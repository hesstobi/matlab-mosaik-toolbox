classdef ModelA < handle
	properties (Access = private)
		i
	end

	methods
		function model = ModelA(i)
			model.i = i;
		end

		function val = next(model)
			%Model produces continuosly increasing integers.
			val = model.i;
			model.i = model.i + 1;
		end

		function val = send(model, i)
			val = model.next();
		end
	end
end

