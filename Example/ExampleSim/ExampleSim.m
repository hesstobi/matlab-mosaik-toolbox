classdef ExampleSim < MosaikAPI.Simulator

	properties
		sid;
		step_size;
		value;
		simulators = cell.empty;		
	end

	methods 
		function sim = ExampleSim(server)
			example_sim_meta = struct( ...
			'models', struct( ...
				'A', struct( ...
					'public', true, 'params', {{'init_val', []}}, 'attrs', {{'val_out', 'dummy_out'}} ...
					), ...
				'B', struct( ...
					'public', true, 'params', {{'init_val', []}}, 'attrs', {{'val_in', 'val_out', 'dummy_in'}} ...
					) ...
				), ...
			'extra_methods', {{'example_method', []}} ...
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

		function entity_list = create(sim, args, kwargs)			
			num = args{1};
			model = args{2};
			if isfield(kwargs, 'init_val')
				init_val = kwargs.init_val;
			else
				init_val = 0;
			end

			msim = ModelSimulator(model, num, init_val);
			sim.simulators(end+1) = {msim};
			sim_id = numel(sim.simulators);
			entity_list = cell.empty;
			for i = 1:numel(msim.instances)
				l.('eid') = strcat('i', num2str(sim_id),'_',num2str(i));
				l.('type') = model;
				l.('rel') = {{}};
				entity_list(end+1) = {l};
			end

			% Adds empty cell for JSONlab
			if eq(numel(entity_list), 1)
				entity_list(end+1) = {[]};
			end
		end

		function time_next_step = step(sim, args, ~)
		if iscell(args)
				time = args{1};
				inputs = args{2};
			else
				time = args;
				inputs = struct;
		end

		progress = sim.as_get_progress();
		disp(progress);
		%related_entities = sim.as_get_related_entities();
		%disp(related_entities);

			for i = 1:numel(sim.simulators)
				sim_inputs = cell(1, numel(sim.simulators{i}.instances));
				for j = 1:numel(sim_inputs)
					eid = strcat('i', num2str(i),'_',num2str(j));
					fn = fieldnames(inputs);
					for k = 1:numel(fn)
						if strcmp(eid,fn{k})
							vl = inputs.(eid).('val_in');
							vl_fn = fieldnames(vl);
							sm = 0;
							for l = 1:numel(vl)
								sm = sm + vl.(vl_fn{1});
							end
							sim_inputs(j) = {sm};
						end
					end
				end
				for j = 1:numel(sim.step_size)
					sim.simulators{i}.step(sim_inputs);
				end
			end
			time_next_step = time + sim.step_size;
		end

		function data = get_data(sim, args, ~)
			outputs = args{1};

			fn = fieldnames(outputs);
			for i = 1:numel(fn)
				for j = 1:numel(outputs.(fn{i}))
					if strcmp(outputs.(fn{i}){j}, 'val_out')
						sid_eid = strsplit(fn{i}, 'i');
						sid_eid = strsplit(sid_eid{2}, '_');
						tmp.fn{i}.(outputs.(fn{i}){j}) = sim.simulators{str2double(sid_eid{1})}.results{str2double(sid_eid{2})};
						data.(fn{i}) = tmp.fn{i};
					end
				end
			end
		end

	end

	methods

		function example_method(~, ~, ~)
		end

	end

end
