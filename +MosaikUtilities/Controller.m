classdef Controller < MosaikAPI.Simulator
	% CONTROLLER   Controller Superclass
	%   Provides data fetching and controlling scheduling methods

	properties

		step_size = 1	% Simulator step size

	end

	methods

		function this = Controller(varargin)
			% Constructor of the class Controller
            %
            % Parameter:
            %  - varargin: Optional arguments.
            %
            % Return:
            %  - this: Controller object

            this = this@MosaikAPI.Simulator(varargin{:});
            
		end

		function time_next_step = step(this,time,varargin)
			%

			data = this.concentrateInputs(inputs);
			schedule = this.makeSchedule(data);
			this.mosaik.set_data(schedule);

			time_next_step = this.step_size + time;

		end

		function value = getValue(this,id,attr)
			%

			output.(id) = attr;
			data = this.mosaik.get_data(output);
			val = data.(id).resistance;
            
        end

	end

	methods (Abstract)

		% Abstract creation method.
		create(this,num,model,varargin);

		% Abstract scheduling method.
		makeSchedule(this,inputs);

	end

end