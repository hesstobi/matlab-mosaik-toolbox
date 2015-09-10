classdef Display < MosaikAPI.Simulator
    %DISPLAY display simulation results
    %   Detailed explanation goes here
    
    properties
        sid;
        step_size;
        data = struct;
        timeline = [];
    end
    
    methods
        function sim = Display(server)
			display_meta = struct( ...
			'models', struct( ...				
				'Graph', struct( ...
					'public', true, 'params', {{}}, 'attrs', {{'data_in'}} ...
					) ...
				) ...
			);
			sim = sim@MosaikAPI.Simulator(server, display_meta);
		end

        function meta = init(sim, args, kwargs)
            sid = args{1};
            if isfield(kwargs, 'step_size')
                step_size = kwargs.step_size;
            else
                step_size = 10;
            end

            sim.sid = sid;
            sim.step_size = step_size;

            meta = sim.meta;
        end

        function entity_list = create(~, args, ~)
            num = args{1};
            if ~eq(num, 1)
                error('Only one display allowed.');
            end
            model = args{2};

            l.('eid') = strcat('d', num2str(num - 1));
            l.('type') = model;
            l.('rel') = {{}};

            entity_list = {l};

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
            sim.timeline(end+1) = progress;

            fn_eid = fieldnames(inputs);
            fn_attr = fieldnames(inputs.(fn_eid{1}));
            if (strcmp(fn_attr{1}, 'data_in'))                
                fn_src_full_id = fieldnames(inputs.(fn_eid{1}).(fn_attr{1}));                
                for i = 1:numel(fn_src_full_id)
                    fn_val = fieldnames(inputs.(fn_eid{1}).(fn_attr{1}).(fn_src_full_id{i}));                                   
                    for j = 1:numel(fn_val)
                        if ~isfield(sim.data, fn_src_full_id{i})
                            sim.data.(fn_src_full_id{i}) = struct();
                        end
                        if ~isfield(sim.data.(fn_src_full_id{i}), fn_val{j})
                            sim.data.(fn_src_full_id{i}).(fn_val{j}) = [inputs.(fn_eid{1}).(fn_attr{1}).(fn_src_full_id{i}).(fn_val{j})];
                        else
                            data = sim.data.(fn_src_full_id{i}).(fn_val{j});
                            data(end+1) = inputs.(fn_eid{1}).(fn_attr{1}).(fn_src_full_id{i}).(fn_val{j}); %#ok<*AGROW>
                            sim.data.(fn_src_full_id{i}).(fn_val{j}) = data;
                        end
                    end
                end
            end

            time_next_step = time + sim.step_size;
        end

        function data = get_data(~, ~, ~)
            data = struct;
        end

        function stop = stop(sim, ~, ~)
            x = sim.timeline;
            fn_src_full_id = fieldnames(sim.data);
            rels = sim.as_get_related_entities(strcat(sim.sid, '.d0'));
            data = struct; %#ok<*PROP>
            for i  = 1:numel(fn_src_full_id)
                ent_type = rels.(fn_src_full_id{i}).type;
                if ~isfield(data, ent_type)
                    data.(ent_type) = struct;
                end
                fn_val = fieldnames(sim.data.(fn_src_full_id{i}));
                for j = 1:numel(fn_val)
                    if ~isfield(data.(ent_type), fn_val{j})
                        data.(ent_type).(fn_val{j}).graph = [];
                        data.(ent_type).(fn_val{j}).leg = cell.empty;                    
                    end
                    data.(ent_type).(fn_val{j}).leg(end+1) = {strcat(strrep(strrep(fn_src_full_id{i}, '_0x2D_', '-'), '_0x2E_', '.'), '-', fn_val{j})};
                    disp(strcat(fn_src_full_id{i}, fn_val{j}));
                    disp(sim.data.(fn_src_full_id{i}).(fn_val{j}));
                    data.(ent_type).(fn_val{j}).graph = cat(1, data.(ent_type).(fn_val{j}).graph, sim.data.(fn_src_full_id{i}).(fn_val{j}));
                end
            end
            fn_types = fieldnames(data);
            for i = 1:numel(fn_types)
                fn_graphs = fieldnames(data.(fn_types{i}));
                for j = 1:numel(fn_graphs)
                    figure;
                    plot(x, data.(fn_types{i}).(fn_graphs{j}).graph);
                    leg = legend(data.(fn_types{i}).(fn_graphs{j}).leg);
                    set(leg, 'Interpreter', 'none');
                end
            end
            stop = ('stop');
        end
    end    
end

