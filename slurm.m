classdef slurm
    %SFOR Function for submittibeccng SLURM job arrays.
    %   Detailed explanation goes here
    
    properties
        account;
        cpus_per_task=1;
        mem=1500;
        time=duration(0,15,0);
        pass_workspace=0;
        workspace='.matlab_slurm';
        sdtout % default = workspace,'out.txt'
        sdterr
        debug=0;
        dummy=0;
        arrayMax;
        qos='debug';
    end
    
    
    methods (Access='private' )
        function waitOn(obj, jobid, size)
            bar_length = 40;
            %clc;
            disp('\n');
            throbber = ["/ ", "- ", "\\ ", "| "];
            count = 1;
            % Yanked from Girmi Schouten
            if usejava('desktop')  % Check if GUI or CLI
                endStr = repelem("\b", 16 + bar_length);
            else
                %endStr = "\033[1F\033[2K\r";
                endStr = "\r";
            end            
            while 1
                squeuecmd = ['squeue -j ', jobid, ' --array --format %t'];
                [submitstatus, returnstring]=system(strjoin(squeuecmd,''));
                returnarray = split(returnstring);
                all_count = length(returnarray)-2;
                
                if submitstatus ~= 0
                    error(returnstring);
                end
                if all_count < 1
                    break
                end
                
                run_count = nnz(strcmp(returnarray,'R'));
                pend_count = all_count - run_count;

                barSoFar = repmat(char(9617), 1, floor(bar_length*pend_count/size)+1);
                barSoFar = [repmat(char(9618), 1, floor(bar_length*run_count/size))+1, barSoFar];
                barSoFar = pad(barSoFar, bar_length, 'left', char(9608));
                fprintf(strjoin([endStr, 'Progress: |', barSoFar, '|  ', throbber(count)], ''));
                
                if count > 3
                    count = 1;
                else
                    count = count + 1;
                end
                             
                pause(2);
                
            end
            fprintf(strjoin([endStr, 'Progress: |', pad('', bar_length, 'left', char(9608)), '|  ', throbber(count)], '\n'));
        end
    end
    methods
        function obj=slurm()
           disp('New Slurm controller');
        end
        function sfor(obj, functionHandle, inputArray)

            % TODO: Validate funtion.
            %       Allow multi-input funtions.
            if obj.debug, properties(obj), end

            workspacename = fullfile(obj.workspace, 'workspace.mat');
            handlename = fullfile(obj.workspace, 'handle.m');
            [~,~]=mkdir(obj.workspace);

            save(workspacename);
            save(handlename,'functionHandle');
            mtlbcmd = ['disp(starting MATLAB call);'];
            
            if obj.pass_workspace
                mtlbcmd=[mtlbcmd, "load('", workspacename,"');"];
            end
            mtlbcmd=[mtlbcmd, "load('", handlename,"');",...
                "functionHandle(\${SLURM_ARRAY_TASK_ID});",...
                "disp(starting MATLAB call);"];
            if obj.debug, disp(strjoin(['MATLAB CMD: ',mtlbcmd], '')), end

            % Construct slurm job.
            bshcmd=['matlab -nodisplay -r \"', mtlbcmd, '\"'];
            if obj.debug, disp(strjoin(['BASH CMD: ',bshcmd], '')), end
            arraystr = strrep(mat2str(inputArray),' ',',');
            arraystr = arraystr(2:end-1);
            
            if obj.arrayMax > 0
                    arraystr = [arraystr, '%', num2str(obj.arrayMax)];
            end
            
            cmd = ['sbatch',...
                ' --job-name ', 'test%x',...
                ' --cpus-per-task ', string(obj.cpus_per_task),...
                ' --mem ', string(obj.mem),...
                ' --open-mode ', 'append',...
                ' --time ', char(obj.time),...
                ' --array ', arraystr];
                
                if exist('obj.sdtout','var')
                    cmd = [cmd, ' --output ', obj.sdtout];
                else
                    cmd = [cmd, ' --output ', obj.workspace, '/output.txt'];
                end
                if exist('obj.account','var')
                    cmd = [cmd, ' --account ', obj.account];
                end
                if exist('obj.error','var')
                    cmd = [cmd, ' --error ', obj.error];
                end
                cmd = [cmd, ' --wrap "',  bshcmd, '"'];
                
            
            if obj.debug, disp(strjoin(['FULL CMD: ',cmd], '')), end
            if obj.dummy
                jobidstring=strjoin(cmd, '');
                submitstatus=0;
            else
                [submitstatus, jobidstring]=system(strjoin(cmd, ''));
            end
            if submitstatus
                error(jobidstring);
            end
            jobidarray=split(jobidstring, ' ');
            jobid=strtrim(jobidarray(4));
            obj.waitOn(jobid, length(inputArray));
%             chaser_cmd=['srun '];
%             if exist('obj.qos','var')
%                 chaser_cmd = [chaser_cmd, ' --qos ', obj.qos];
%             end
%             chaser_cmd = [chaser_cmd,' --job-name chaser',' --dependency after:',jobid, ' --time ','00:00:01', ' true'];
%             if obj.debug, disp(strjoin(['CHASER CMD: ', chaser_cmd], '')), end
%             [submitstatus, jobidstring]=system(strjoin(chaser_cmd, ''));
%             if submitstatus
%                 error(jobidstring);
%             end
            rmdir(obj.workspace, 's');
        end
    end
end

