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
        debug=0;
        qos='debug';
    end
    
    
    
    methods
        function sfor(obj, functionHandle, inputArray)

            % TODO: Validate funtion.
            %       Allow multi-input funtions.
            if obj.debug, properties(obj), end

            workspacename = fullfile(obj.workspace, 'workspace.mat');
            handlename = fullfile(obj.workspace, 'handle.m');
            mkdir(obj.workspace);

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
            bshcmd=['matlab -nodisplay -r', mtlbcmd];
            if obj.debug, disp(strjoin(['BASH CMD: ',bshcmd], '')), end
                
            cmd = ['sbatch',...
                ' --job-name ', 'test%x',...
                ' --cpus-per-task ', string(obj.cpus_per_task),...
                ' --mem ', string(obj.mem),...
                ' --output ', fullfile(obj.workspace,'all.log'),...
                ' --open-mode ', 'append',...
                ' --time ', char(obj.time),...
                ' --array ', strjoin(inputArray,',')];
            
                if exist('obj.account','var')
                    cmd = [cmd, ' --account ', obj.account];
                end
                if exist('obj.qos','var')
                    cmd = [cmd, ' --qos ', obj.qos];
                end
                cmd = [cmd, '--wrap "',  bshcmd, '"'];
                
            
            if obj.debug, disp(strjoin(['FULL CMD: ',cmd], '')), end

            [submitstatus, jobidstring]=system(strjoin(cmd, ''));
            if submitstatus
                error(jobidstring);
            end
            jobidarray=split(jobidstring, ' ');
            jobid=strtrim(jobidarray(4));
            chaser_cmd = ['srun','--job-name','--qos', obj.qos, 'chaser','--dependency', (strcat('after:',jobid)), '--time','00:00:01', 'true'];
            if obj.debug, disp(strjoin(['CHASER CMD: ', cmd], '')), end
            [submitstatus, jobidstring]=system(strjoin(chaser_cmd, ' '));
            if submitstatus
                error(jobidstring);
            end
        end
    end
end

