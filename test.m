inputs={[1,1],[1,2],[5,10],[20,2]};
%sc=slurm();
thing=@timesten;
thing(inputs(:,1));

function output = timesten(input1, input2)
    output(index) = input * input2;
end


