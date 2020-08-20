sc = slurm();
%sc.debug = 1;
sc.arrayMax = 2;
sc.sfor(@exampleFunction, 1:12);

function exampleFunction(input)
    disp(input);
    pause(randi([1,100],1));
end


