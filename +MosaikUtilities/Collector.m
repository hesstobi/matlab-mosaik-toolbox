classdef Collector < MosaikAPI.Simulator
    % COLLECTOR   A simple data collector that prints all data when the simulation finishes.
    %   Shows required data as table, graphical plot and saves it. To capture it, connect
    %   the required data to the collector.
    
    properties (Constant)
        model = 'Collector';
    end
    
    properties
        data = [];                  % Data array
        step_size = 1;              % Interval after which the collector saves data
        save_path = [];             % Data save path
        eid = [];                   % Collector eid
        graphical_output = false;   % Turn on/off graphical output
    end
    
    methods 
		function this = Collector(varargin)
            % Constructor of the class Collector.
            this = this@MosaikAPI.Simulator(varargin{:});
        end
        
        function value = meta(this)
            % Creates meta struct and adds collector meta content.
            value = meta@MosaikAPI.Simulator(this);
            
            value.extra_methods = {'save_results',[]};
            
            value.models.(this.model).public = true;
            value.models.(this.model).attrs = {};
            value.models.(this.model).params = {'graphical_output',[]};
            value.models.(this.model).any_inputs = true;
            
        end
        
    end
    
    methods
        
        function dscrList = create(this,num,model,varargin)
            % Creates a collector instance. Only one collector instance possible.
            if num>1 || ~isempty(this.eid)
                error('Can only create one instance of Collector.')
            end

            p = inputParser;
            addOptional(p,'graphical_output',false,@(x)validateattributes(x,{'logical'},{'nonempty'}));
            parse(p,varargin{:});
            
            this.graphical_output = p.Results.graphical_output;           
            this.eid = model;
           
            s.eid = this.eid;
            s.type = this.model;
            dscrList = horzcat({s},{[]});
        end
        
               
                
        function new_time = step(this,time,inputs)
            % Receives data from all given inputs.
            inputs = inputs.(this.eid);
            
            names = cellfun(@(x) strcat(fieldnames(inputs.(x)),'_x_',x),fieldnames(inputs),'UniformOutput',false);
            names = cellfun(@(x) strrep(x,'_0x2D_','_'),names,'UniformOutput',false);   % Changing hex code to original symbol not allowed. Using '_' instead.
            names = cellfun(@(x) strrep(x,'_0x2E_','_'),names,'UniformOutput',false);
            names = vertcat(names{:});
            names{end+1} = 'Time';
            
            values = cellfun(@(x) struct2cell(inputs.(x)),fieldnames(inputs),'UniformOutput',false);
            values = vertcat(values{:});
            
            t = cell2table(values');
            t.Time = time;

            t.Properties.VariableNames = names;
                    
            this.data = vertcat(this.data,t);
            if size(this.data,1) == 1
                this.data.Properties.VariableNames = names;
            end

            disp(savejson('',names));
            
            
            new_time = time + this.step_size;
           
        end
        
        
        function get_data(~,~)
            error('The Collector can not return data');           
        end
        
                
        function finalize(this)
            % Previews data in a table, plots and saves it.

            disp(this.data);

            if this.graphical_output
                this.plot_data();
            end

            pause;
           
            if ~isempty(this.save_path)
                this.save_results();
            else
                pause
            end

        end

    end

    methods (Access=private)

        function plot_data(this)
            x = this.data.Time;
            this.data.Time = [];
            names = this.data.Properties.VariableNames;
            types = cellfun(@(y) y{end},cellfun(@(x) strsplit(x,'_x_'),names,'UniformOutput',false),'UniformOutput',false);
            types = unique(types);
            for i = 1:numel(types)
                typ = types{i};
                figure('name',typ);
                leg = {};
                for j = 1:numel(names)
                    cur_typ = strsplit(names{j},'_x_');
                    cur_typ = cur_typ{end};
                    if strcmp(cur_typ,typ)
                        hold on;
                        plot(x,this.data.(names{j}));
                        name = strrep(names{j},['_x_' cur_typ],'');
                        leg(end+1) = {name};
                    end
                end
                set(legend(leg),'Interpreter','none');
            end

        end
        
        function save_results(this)
            results = this.data;
            save(this.save_path,'results');

        end
        
    end
    
end

