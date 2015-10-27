classdef ExampleMas < MosaikAPI.ModelSimulator
	% EXAMPLEMAS   Simulator to demonstrate async requests.
	%   Demonstrates all asynchronous request methods with ExampleSim model.

	properties

        providedModels = {'Agent'}

    end

	methods

		function this = ExampleMas(varargin)
			% Constructor of the class ExampleMas

			this = this@MosaikAPI.ModelSimulator(varargin{:});

		end

		function time_next_step = step(this,time,varargin)
			% Gets and prints progress then returns to superclass function.

			progress = this.mosaik.get_progress;
			disp(strcat('Progress: ',num2str(progress,2)));

			time_next_step = step@MosaikAPI.ModelSimulator(this,time,varargin{1});

		end

	end

end
