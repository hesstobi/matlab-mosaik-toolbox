classdef Controller < MosaikAPI.Simulator
	% CONTROLLER   Controller Superclass
	%   Provides data fetching and controlling scheduling methods

	properties

		step_size = 1	% Simulator step size

	end

	methods

		function this = Controller(varargin)
			% Constructor of the class Controller.
			%
			% Parameter:
			%  - varargin: Optional arguments.
			%
			% Return:
			%  - this: Controller object.

			this = this@MosaikAPI.Simulator(varargin{:});
			
		end

		function ctrl_list = create(this,num,model,varargin)
			% Creates a controller instance. Only one collector instance possible.
			%
			% Parameter:
			%
			%  - num: Double argument; amount of controllers.
			%  - model: String argument; controller eid prefix.
			%  - varargin: Optional arguments; graphical output, save path.
			%
			% Return:
			%
			%  - ctrl_list: Cell object; structs with created collector
			%                           information.

			ctrl_list = [];

			for i = this.amount:this.amount+num-1

				this.eid = [model,'_',num2str(i)];
				ctrl.eid = this.eid;
				ctrl.type = 'Controller';
				ctrl.rel = {};
				ctrl_list{end+1} = ctrl;

			end

			disp(this.amount);
			this.amount = this.amount + num;
			disp(this.amount);

		end

		function time_next_step = step(this,time,varargin)
			% Receives data from all given inputs.
			%
			% Parameter:
			%  - time: Double argument; time of this simulation step.
			%  - varargin: Optional arguments; input values.
			%
			% Return:
			%  - time_next_step: Double object; time of next simulation step.

			if ~isempty(varargin)
				schedule = this.makeSchedule(varargin{1});
				this.mosaik.set_data(schedule);
			end

			time_next_step = this.step_size + time;

		end

		function value = getValue(this,id,attr)
			% Receives data from all given inputs.
			%
			% Parameter:
			%  - id: String argument; model id.
			%  - attr: String arguments; requested attribute.        
			%
			% Return:
			%  - value: Double object; requested value.

			output.(id) = {attr};
			data = this.mosaik.get_data(output);
			value = data.(id).(attr);
			
		end

		function entities = getRelatedWithoutUtility(this,entity)
			% Removes utilites from related entities.
			%
			% Parameter:
			%  - entity: String argument; model id.
			%  - attr: String arguments; requested attribute.              
			%
			% Return:
			%  - entities: Struct object; related entities.

			rels = this.mosaik.get_related_entities(entity);
			rel  = fieldnames(rels);

			for i = 1:numel(rel)

				if ~strcmp(rels.(rel{i}).type,'Controller') && ~strcmp(rels.(rel{i}).type,'Collector')

					entities.(rel{i}) = rels.(rel{i});

				end

			end

		end

	end

	methods (Abstract)

		% Creates output values for controlled models based
		% on input values and controller function.
		%
		% Parameter:
		%  - inputs: Struct argument; input values.            
		%
		% Return:
		%  - schedule: Struct object; output values.
		schedule = makeSchedule(this,inputs);

	end

end