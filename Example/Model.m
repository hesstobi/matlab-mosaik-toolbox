classdef Model < MosaikAPI.Model
    %TESTMODELL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
       delta = 1
       val = 0
    end
    
    methods 
       
        function this = Model(eid,varargin)
            this = this@MosaikAPI.Model(eid);
            
            p = inputParser;
            addOptional(p,'init_value',0,@(x)validateattributes(x,{'numeric'},{'scalar'}));
            parse(p,varargin{:});
            
            this.val = p.Results.init_value;          
        end
        
        
        function step(this,varargin)
           this.val = this.val + this.delta; 
        end
       
        
    end
    
       
    methods (Static)
        
        function value = meta()
           value.public = true;
           value.attrs = {'delta', 'val'};
           value.params = {'init_value',[]};
           value.any_inputs = false;
        end
    end
    
    
end

