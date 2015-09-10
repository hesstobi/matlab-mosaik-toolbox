classdef ExampleMas < MosaikAPI.Simulator

	properties
		sid;
		step_size;
		value;
		agents = cell.empty;
		rel;
		msim;				
	end

	methods 

		function sim = ExampleMas(server)
			example_sim_meta = struct( ...
			'models', struct( ...
				'Agent', struct( ...
					'public', true, 'params', {{}}, 'attrs', {{'link'}} ...
					) ...
				) ...
			);
			sim = sim@MosaikAPI.Simulator(server, example_sim_meta);
		end

	end

	methods

		function meta = init(sim, args, kwargs)
			sid = args{1};
			if isfield(kwargs, 'step_size')
				step_size = kwargs.step_size;
			else
				step_size = 1;
			end

			sim.sid = sid;
			sim.step_size = step_size;

			meta = sim.meta;			
			             
			
		end

		function agents = create(sim, args, ~)			
			num = args{1};
			model = args{2};

			if ~strcmp(model, 'Agent')
				error('Can only create "Agent" models.');
			end

			num_agents = numel(sim.agents);
			agents  = cell.empty;
			for eid = num_agents:num_agents + num - 1
				l.('eid') = num2str(eid);
				l.('type') = model;
				l.('rel') = {{}};
				agents(end+1) = {l};
			end

			for i = 1:numel(agents)
				sim.agents(end+1)  = {agents{i}};
			end

			% Adds empty cell for JSONlab
			if eq(numel(agents), 1)
				agents(end+1) = {[]};
			end
		end

		function time_next_step = step(sim, args, ~)
			if iscell(args)
					time = args{1};
				else
					time = args;
			end

			if eq(time,0)
				c = cell.empty;
				for i = 1:numel(sim.agents)
					a = sim.agents{i};
					c(end+1) = {strcat(sim.sid, '.', a.eid)};
				end
				sim.rel = sim.as_get_related_entities(c);

				fn_src_full_id = fieldnames(sim.rel);
				for i = 1:numel(sim.rel)
					disp(fn_src_full_id{i});
					disp(sim.rel.(fn_src_full_id{i}));
				end
			end

			fn_src_full_id = fieldnames(sim.rel);
			for i = numel(sim.rel)
				rels = sim.rel.(fn_src_full_id{i});
				if strcmp(class(rels), 'cell');
					for j = numel(rels)
						eid = rels{j};
						disp(eid);
						l.(eid) = {'val_out', []};
					end
				end
			end
			if ~eq(exist('l'), 0)
				data = sim.as_get_data(l);
				disp(data);
			end			

			inputs = struct;
			for i = 1:numel(sim.agents)
				a = sim.agents{i};
				full_id = strcat(sim.sid, '.', a.eid);
				if isfield(sim.rel, full_id)
					for j = 1:numel(sim.rel.(full_id))
						eid = sim.rel.(full_id)(j);
						l.(eid) = struct('val_in', 23);
					end
					inputs.(full_id) = l;
				end
			end
			sim.as_set_data(inputs);

			time_next_step = time + sim.step_size;
		end

		function data = get_data(~, ~, ~)
			data = struct;
		end
	end
end
