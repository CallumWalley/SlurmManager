classdef slurm
    %SFOR Function for submittibeccng SLURM job arrays.
    %   Detailed explanation goes here
    
    properties
        account
        cpus_per_task=1
        mem=1500
        time=duration(0,15,0)
        workspace='.matlab_slurm'
        qos='debug'
    end
    
    
    
    methods
        function sfor(obj, functionHandle, inputArray)
            mkdir(obj.workspace);
            workspacename = fullfile(obj.workspace, 'workspace.mat');
            outputname = fullfile(obj.workspace, '\${SLURM_ARRAY_TASK_ID}.mat');
            save(workspacename);
            range = strcat('1-',string(length(inputArray)));
            
            mtlbcmd = [strcat("load('", workspacename,"');"),...
                "functionHandle(inputArray(:,\${SLURM_ARRAY_TASK_ID}));",...
                "save(", strcat("'", outputname, "'"),")"];
            disp(strjoin(mtlbcmd, ' '));
            % Construct slurm job.
            bshcmd=['matlab', '-nodisplay', '-r',...
                strcat('\"', strjoin(mtlbcmd,' '), '\"')];
            disp(strjoin(bshcmd, ' '));
            cmd = ['sbatch',...
                '--job-name', 'test%x',...
                '--cpus-per-task', string(obj.cpus_per_task),...
                '--mem', string(obj.mem),...
                '--output', fullfile(obj.workspace,'all.log'),...
                '--open-mode', 'append',...
                '--time', char(obj.time),...
                '--array', range,...
                '--wrap', strcat('"',strjoin(bshcmd,' '),'"')];
            
            disp(strjoin(cmd, ' '));
            %
            [submitstatus jobidstring]=system(strjoin(cmd, ' '));
            if submitstatus
                error(jobidstring);
            end
            jobidarray=split(jobidstring, ' ');
            jobid=strtrim(jobidarray(4));
            chaser_cmd = ['srun','--job-name','--qos', obj.qos, 'chaser','--dependency', (strcat('after:',jobid)), '--time','00:00:01', 'true'];
            disp(strjoin(chaser_cmd, ' '));
            [submitstatus jobidstring]=system(strjoin(chaser_cmd, ' '));
            if submitstatus
                error(jobidstring);
            end
            
            for x=1:length(inputArray)
                load(fullfile(obj.workspace, strcat(string(x), '.mat')));
            end
            %             syste
            %system(cmd)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
        end
    end
end

