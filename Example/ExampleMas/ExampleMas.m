classdef ExampleMas < MosaikAPI.ModelSimulator
	% EXAMPLEMAS   Basic example simulator.
	%   Demonstrates all asynchronous request methods with ExampleSim.

	properties

        providedModels = {'Agent'}	% Models which are provided by the simulator

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

			if ~isempty(varargin)

				time_next_step = step@MosaikAPI.ModelSimulator(this,time,varargin{1});
			
			else

				time_next_step = step@MosaikAPI.ModelSimulator(this,time);

			end

		end

	end

end
