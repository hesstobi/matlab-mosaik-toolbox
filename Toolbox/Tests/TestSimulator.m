classdef TestSimulator < MosaikAPI.Simulator
    %TESTSIMULATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
       parameter1
       parameter2
    end
    
    methods
        
        function this = TestSimulator(varargin)
            this = this@MosaikAPI.Simulator(varargin{:});
        end
        
        function out = create(this,num,model,varargin)
           
            out.num = num;
            out.model = model;
            out.params = varargin;
            
        end
        
        function  out = step(this,time,varargin)
            
            if ~isempty(varargin)
                out.inputs = varargin{1};
            else
               out.inputs = 'none'; 
            end
            
            out.time = time;
            
        end
        
        function out = get_data(this,output)
           
            out.output = output;
            
        end
        
    end
    
end

