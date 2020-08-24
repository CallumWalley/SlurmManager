<<<<<<< HEAD
sm = SlurmManager();
%sc.debug = 1;
sm.arrayMax = 2;
sm.sfor(@exampleFunction, 1:12);

function exampleFunction(input_)
    disp(input_);
=======
sc = slurm();
%sc.debug = 1;
sc.arrayMax = 2;
sc.sfor(@exampleFunction, 1:12);

function exampleFunction(input)
    disp(input);
>>>>>>> bbbefac3711fa41fd89fcd7d54d6c29ed8eb319f
    pause(randi([1,100],1));
end


<<<<<<< HEAD

=======
>>>>>>> bbbefac3711fa41fd89fcd7d54d6c29ed8eb319f
