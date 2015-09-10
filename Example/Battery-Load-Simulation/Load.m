classdef Load < MosaikAPI.Simulator
	%LOAD electrical load simulator for MOSAIK
	%   Simulates a load with given parameters resistance R, operating voltage U_R and tolerance delta, which together
	%   define the range operating voltages.
	%   Based on the battery given voltage U, resistance R and time (step.size) t , the load consumes capacitance Q in the form
	%   Q = (U/R) * t.
	%   The simulator has the attribute 'val_in', which is the battery voltage U.
	%   To show the functionality of asynchronous requests, the simulator requests the battery it's connected to via get_related_entities
	%   and feeds it the consumed capacitance Q via set_data.

	properties
		sid;
		step_size;
		value;
		loads = struct;			
		amount = 0;
	end

	methods 

		function sim = Load(server)
			load_meta = struct( ...
			'models', struct( ...				
				'Load', struct( ...
					'public', true, 'params', {{'resistance', 'voltage', 'tolerance'}}, 'attrs', {{'voltage_in', 'data_out'}} ...
					) ...
				) ...
			);
			sim = sim@MosaikAPI.Simulator(server, load_meta);
		end

	end

	methods

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

		function entity_list = create(sim, args, kwargs)			
			num = args{1};
			model = args{2};
			if isfield(kwargs, 'resistance')
				resistance = kwargs.resistance;
			else
				resistance = 1000;
			end
			if isfield(kwargs, 'voltage')
				voltage = kwargs.voltage;
			else
				voltage = 10;
			end
			if isfield(kwargs, 'tolerance')
				tolerance = kwargs.tolerance;
			else
				tolerance = 1000;
			end

			entity_list = cell.empty;
			for i = 1:num
				l.('eid') = strcat('l', num2str(sim.amount));
				l.('type') = model;
				l.('rel') = {{}};
				entity_list(end+1) = {l};
				sim.loads.(l.('eid')).('resistance') = resistance;
				sim.loads.(l.('eid')).('voltage') = voltage;
				sim.loads.(l.('eid')).('tolerance') = tolerance;
				sim.loads.(l.('eid')).('consumed_capacitance') = 0;
				sim.amount = sim.amount + 1;
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

			fn_eid = fieldnames(inputs);
			for i = 1:numel(fn_eid)
				voltage_in = inputs.(fn_eid{i}).voltage_in;
				fn_src_full_id = fieldnames(voltage_in);
				if eq(numel(fn_src_full_id), 1)
					voltage_in= inputs.(fn_eid{i}).voltage_in.(fn_src_full_id{1});
				else
					error('A load can only be connected to one battery.')
				end
				voltage = sim.loads.(fn_eid{i}).voltage;
				tolerance = sim.loads.(fn_eid{i}).tolerance;
				resistance = sim.loads.(fn_eid{i}).resistance;
				if ge(voltage_in, (voltage * (1 - tolerance))) && le(voltage_in, (voltage * (1 + tolerance)))
					consumed_capacitance = ((voltage_in / resistance) * sim.step_size);
				else
					consumed_capacitance = 0;
				end

				sim.loads.(fn_eid{i}).('consumed_capacitance') = sim.loads.(fn_eid{i}).('consumed_capacitance') + consumed_capacitance;

				rels = sim.as_get_related_entities(strcat(sim.sid, '.', fn_eid{i}));
				fn_src_full_id = fieldnames(rels);
				l = struct;
				for j = 1:numel(fn_src_full_id)
					if ~strcmp(rels.(fn_src_full_id{j}).type, 'Graph')
						l.(fn_src_full_id{j}) = struct('consumed_capacitance', consumed_capacitance);
					end			
				end
				sid = strrep(sim.sid, '-', '_0x2D_'); % '_0x2D_' is hex for '-'
				m = struct;
				m.(strcat(sid, '_0x2E_', fn_eid{i})) = l; % '_0x2E_' is hex for '.'; JSONLab will convert it, MATLab can not have points in struct fields.
				sim.as_set_data(m);
			end

			time_next_step = time + sim.step_size;
		end

		function data = get_data(sim, args, ~)
			outputs = args{1};

			fn_eid = fieldnames(outputs);
			for i = 1:numel(fn_eid)
				for j = 1:numel(outputs.(fn_eid{i}))
					if strcmp(outputs.(fn_eid{i}){j}, 'data_out')
						data.(fn_eid{i}).('data_out').('consumed_capacitance') = sim.loads.(fn_eid{i}).('consumed_capacitance'); % Battery voltage U
					end
				end
			end
		end
	end
end
