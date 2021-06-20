classdef SlurmManager
    % SlurmManager Class for managing Slurm jobs within MATLAB.
    %   Detailed explanation goes here
    
    properties
        state='UNKNOWN';
        p = inputParser;
    end
    
    properties (Access='private' )
         bar_length = 40;
         throbber = ["/ ", "- ", "\\ ", "| "];
    end
    methods (Access='public' )
        function obj = SlurmManager()
        end
        function queue()
            
        end
        function acct()
            
        end
    end
end

