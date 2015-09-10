classdef Battery < MosaikAPI.Simulator
	% BATTERY battery simulator for MOSAIK
	%   Simulates a battery with given parameters initial capacitance Q_0 and voltage at that capacitance U_0.
	%   The voltage U drops with decreasing capacitance Q in the form U = U_0 * ((Q/Q_0) ^ 0.5).
	%   The simulator has the attributes 'val_in', which is the consumed capacitance by all connected loads Q and 'val_out', which is the
	%   current voltage U.
	%   To show the functionality of asynchronous requests, the simulator requests the progress every step via get_progress and saves it together with the
	%   corresponding voltage U and displays it as a graph after the simulation is done.

	properties
		sid;
		step_size;
		value;
		batteries = struct;
		amount = 0;			
	end

	methods 

		function sim = Battery(server)
			battery_meta = struct( ...
			'models', struct( ...
				'Battery', struct( ...
					'public', true, 'params', {{'init_capacitance', 'init_voltage'}}, 'attrs', {{'voltage_out', 'data_out'}} ...
					) ...
				) ...
			);
			sim = sim@MosaikAPI.Simulator(server, battery_meta);
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
			if isfield(kwargs, 'init_capacitance')
				init_capacitance = kwargs.init_capacitance;
			else
				init_capacitance = 1000;
			end

			if isfield(kwargs, 'init_voltage')
				init_voltage = kwargs.init_voltage;
			else
				init_voltage = 1000;
			end

			entity_list = cell.empty;
			for i = 1:num
				l.('eid') = strcat('b', num2str(sim.amount));
				l.('type') = model;
				l.('rel') = {{}};
				entity_list(end+1) = {l};
				% Initial capacitance
				sim.batteries.(l.('eid')).('init_capacitance') = init_capacitance;
				% Initial voltage
				sim.batteries.(l.('eid')).('init_voltage') = init_voltage;
				% Current capacitance
				sim.batteries.(l.('eid')).('capacitance') = init_capacitance;
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
				if isfield(inputs.(fn_eid{i}), 'consumed_capacitance')
					consumed_capacitance = inputs.(fn_eid{i}).consumed_capacitance;
					fn_src_full_id = fieldnames(consumed_capacitance);
					vals = 0;
					for j = 1:numel(fn_src_full_id)
						vals = vals + consumed_capacitance.(fn_src_full_id{j});
					end
					% Removes used capacitance from current capacitance
					sim.batteries.(fn_eid{i}).capacitance = sim.batteries.(fn_eid{i}).capacitance - vals;
				end
			end

			time_next_step = time + sim.step_size;
		end

		function data = get_data(sim, args, ~)
			outputs = args{1};

			fn_eid = fieldnames(outputs);
			for i = 1:numel(fn_eid)
				for j = 1:numel(outputs.(fn_eid{i}))
					capacitance = sim.batteries.(fn_eid{i}).capacitance;
					init_capacitance = sim.batteries.(fn_eid{i}).init_capacitance;
					init_voltage = sim.batteries.(fn_eid{i}).init_voltage;
					if strcmp(outputs.(fn_eid{i}){j}, 'voltage_out')						
						data.(fn_eid{i}).('voltage_out') = (((capacitance / init_capacitance) ^ 0.5) * init_voltage); % Battery voltage U
					elseif strcmp(outputs.(fn_eid{i}){j}, 'data_out')
						data.(fn_eid{i}).('data_out').('current_voltage') = (((capacitance / init_capacitance) ^ 0.5) * init_voltage);
						data.(fn_eid{i}).('data_out').('state_of_charge') = capacitance;
					end
				end
			end
		end		
	end
end
