classdef ModelSimulator < handle
	
	properties
		models = struct('A', 'model_a', 'B', 'model_b');
		instances = cell.empty;
		results = cell.empty;
	end

	methods
		function msim = ModelSimulator(model, num_inst, init_val)
			

			for i = 1:num_inst
				inst = str2func(msim.models.(model));
				inst = inst(init_val);
				result = inst.next();
				disp(inst);
				disp(result);
				msim.results(end+1) = {result};
				msim.instances(end+1) = {inst};
			end
		end

		function step(msim, inputs)
            if ~eq(numel(inputs), numel(msim.instances))
            	error('No step configuration for all models given.');
            end
            msim.results = cell.empty;
            for i = 1:numel(inputs)
                disp(msim.instances{i});
                result = msim.instances{i}.send(inputs{i});
                disp(result);
            	msim.results(end+1) = {result};
            end
		end

	end
end