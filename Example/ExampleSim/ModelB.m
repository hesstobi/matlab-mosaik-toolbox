classdef ModelB < handle
	properties (Access = private)
		val
	end

	methods
		function model = ModelB(val)
			model.val = val;
		end

		function new_val = next(model)
			%Model consumes a value end returns the last value consumed.
			new_val = model.val;
			if ~isempty(new_val)
				model.val = new_val;
			end
		end

		function new_val = send(model, val)
			model.val = val;
			new_val = model.next();
        end
	end
end

