classdef ExampleMas < MosaikAPI.Simulator
	% EXAMPLEMAS   Simulator to demonstrate async requests.
	%   Demonstrates all asynchronous request methods.

	properties (Access=private)
		agents = {[]};
		models = struct( ...
			'models',struct( ...
				'Agent',struct( ...
					'public',true, ...
					'params',{{}}, ...
					'attrs',{'link','val_in','val_out'} ...
					) ...
				) ...
			);
	end

	methods

		function this = ExampleMas(varargin)
			this = this@MosaikAPI.Simulator(varargin{:});
		end

		function value = meta(this)
			% Creates meta struct.

			value = meta@MosaikAPI.Simulator(this);

			% Add agent model
			value.models = this.models;
		end

		function agents = create(this,num,model,varargin)

			if ~strcmp(model,'Agent')
				error('Can only create "Agent" models.');
			end

			% Add all created agent models to agent array.
			num_agents = numel(this.agents);
			agents = {[]};
			for i = num_agents:num_agents+num-1
				l.eid = num2str(i);
				l.type = model;
				l.rel = {};
				agents(end+1) = {l};
			end
			this.agents(end+1) = agents;
		end

		function time_next_step = step(this,time,varargin)
			progress = this.mosaik.get_progress;
			disp(strcat('Progress: ',num2str(progress,2)));

			if eq(time,0)
				agents = cellfun(@(x) strcat(this.sid,x.eid),this.agents,'UniformOutput',false);
				this.rel = this.as_get_related_entitites(agents);
				disp(this.rel);
			end

			rels = struct2cell(this.rel)';
			outputs = struct;
			for i = 1:numel(rels)
				rel = rels{i};
				for j = 1:numel(rel)
					outputs.(rel{j}) = {'val_out',[]};
				end
			end
			data = this.mosaik.get_data(outputs);

			disp(savejson('',data));

			inputs = struct;
			for i = 1:numel(this.agents)
				a = this.agents{i};
				full_id = strcat(this.sid, a.eid);
				for j = 1:numel(this.rel.(full_id))
					eid = this.rel.(full_id){i};
					inputs.(full_id).(this.rel.(full_id){i}).val_in = 23;
				end
			end
			this.mosaik.set_data(inputs);

			time_next_step = time + this.step_size;
		end

	end

end
