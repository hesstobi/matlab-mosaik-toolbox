classdef ExampleSim < MosaikAPI.Simulator

	properties
		sid;
		step_size;
		value;		
		simulators = cell.empty;
        msim;
            
    end
    
    
    methods 
		function sim = ExampleSim(server)
 			sim = sim@MosaikAPI.Simulator(server);
		end
	end

	methods

		function meta = init(sim, args, kwargs)
			sim.sid = args{1};
			A.('public') = true;
			A.('params') = {'init_val', []};
 			A.('attrs') = {'val_out', 'dummy_out'};
 			B.('public') = true;
 			B.('params') = {'init_val', []};
 			B.('attrs') = {'val_in', 'val_out', 'dummy_in'};
 			models.('A') = A;
 			models.('B') = B;
 			example_sim_meta.('models') = models;
 			example_sim_meta.('extra_methods') = {'waua', []};
			if ~isfield(kwargs, 'step_size')
				sim.step_size = 1;
			else
				sim.step_size = kwargs.step_size;
			end			
			example_sim_meta = update_meta(sim, example_sim_meta);
			meta = example_sim_meta;
		end

		function entity_list = create(sim, args, kwargs)
			entity_list = cell.empty;
			num = args{1};
			model = args{2};		
			sim.msim = ModelSimulator(model, num, kwargs.init_val);
			sim.simulators(end+1) = {sim.msim};	
			sim_id = numel(sim.simulators);
			for i = 1:numel(sim.msim.instances)
				l.('eid') = strcat('i', num2str(sim_id),'_',num2str(i));
				l.('type') = model;
				l.('rel') = '[]';
				entity_list(end+1) = {l};
			end
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
            
            progress = sim.get_progress();
            disp(progress);

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

		function extra = wtimes(~, args, kwargs)
			word = args;
			extra = '';
			if ~isfield(kwargs, 'times')
				times = 1;
			else
				times = kwargs.times;
			end
			for i = 1:times
				extra = strcat(extra, word);
			end
		end

	end

end
