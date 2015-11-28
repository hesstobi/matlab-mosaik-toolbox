classdef Model < handle
    % MODEL  Model superclass.
    %   Provides setter and getter methods and defines methodes that models need to implement.
    
    properties

        sim    % Associated simulator
        eid    % Models entitiy id

    end
    
    methods

        function this = Model(sim,eid)
            % Constructor of the class Model.
            %
            % Parameter:
            %
            %  - sim: String argument containing
            %         associated simulator instance.
            %
            %  - eid: String argument containing
            %         model entitiy id.
            %
            % Return:
            %
            %  - this: Model object.

            this.sim = sim;
            this.eid = eid;

        end        
        
        function data = get_data(this,attrs)
            % Returns values for given attributes.
            %
            % Parameter:
            %
            %  - attrs: Cell argument containing
            %           required attributes.
            %
            % Return:
            %
            %  - data: Struct object containing
            %          required data.
            
            attrs = unique(attrs);
            values = cellfun(@(x) this.(x),attrs,'UniformOutput',false);
            data = cell2struct(values,attrs,2);
 
        end        
        
        function set_data(this,data)
            % Sets given values for given attributes.
            %
            % Parameter:
            %
            %  - data: Struct argument containing
            %          target attributes and its
            %          new values.
            %
            % Return:
            %
            %  - none

            attrs = fieldnames(data);

            values = struct2cell(data);
            
            for idx=1:numel(attrs)
                this.(attrs{idx}) = values{idx};
            end
            
        end        
        
        function value = get_attrs(this)
            % Returns all attributes of a model.
            %
            % Parameter:
            %
            %  - none:
            %
            % Return:
            %
            %  - value: Cell object containing
            %           requested attributes.
           
            value = this.meta().attrs;
            value = value(~cellfun(@isempty,value));
            
        end        
        
        function value = modelName(this)
            % Returns model name.
            %
            % Parameter:
            %
            %  - none:
            %
            % Return:
            %
            %  - func: String object containing
            %          model name.

            value = strsplit(class(this),'.');
            value = value{end};

        end
        
    end
 
    methods (Static,Abstract)

        % Creates meta struct with models information.
        %
        % Parameter:
        %  - none
        %
        % Return:
        %  - value: Struct object containing meta information.
        value = meta();

    end

    methods (Abstract)

        % Performs models simulation step.
        %
        % Parameter:
        %  - varargin: Struct object containing optional parameters.
        %
        % Return:
        %  - none
        step(varargin);

    end
        
end
