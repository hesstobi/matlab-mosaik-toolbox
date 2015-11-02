classdef Controller < MosaikAPI.Simulator
	% CONTROLLER   Controller Superclass
	%   Provides data fetching and controlling schedulíng methods

	properties

		step_size	% Simulator step size

	end

	methods

		function this = Controller(varargin)
			% Constructor of the class Controller
            %
            % Parameter:
            %  - varargin: Passes optional arguments to
            %              simulator superclass.
            %
            % Return:
            %  - this: Controller object

            p = inputParser;

		end

		function controller_entity = create(this,num,model)

		function time_next_step = step(this,time,varargin)
			%

			data = this.concentrateInputs(inputs);
			schedule = this.makeSchedule(data);
			this.mosaik.set_data(schedule);

			time_next_step = this.step_size + time;

	end

	methods (Abstract)

		% Abstract scheduling method
		makeSchedule(inputs);

		end

	end

end