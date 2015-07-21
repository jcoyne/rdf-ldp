require 'link_header'

module RDF::LDP
  class Resource

    ##
    # Interaction models are in reverse order of preference for POST/PUT 
    # requests; e.g. if a client sends a request with Resource, RDFSource, and
    # BasicContainer headers, the server gives a basic container.
    INTERACTION_MODELS = {
      RDF::URI('http://www.w3.org/ns/ldp#Resource') => RDF::LDP::RDFSource,
      RDF::LDP::RDFSource.to_uri => RDF::LDP::RDFSource,
      RDF::LDP::Container.to_uri => RDF::LDP::Container,
      RDF::URI('http://www.w3.org/ns/ldp#BasicContainer') => RDF::LDP::Container,
      RDF::LDP::DirectContainer.to_uri => RDF::LDP::DirectContainer,
      RDF::LDP::IndirectContainer.to_uri => RDF::LDP::IndirectContainer,
      RDF::LDP::NonRDFSource.to_uri => RDF::LDP::NonRDFSource
    }.freeze

    CONTAINER_CLASSES = { 
      basic:    RDF::URI('http://www.w3.org/ns/ldp#BasicContainer'),
      direct:   RDF::URI('http://www.w3.org/ns/ldp#DirectContainer'),
      indirect: RDF::URI('http://www.w3.org/ns/ldp#IndirectContainer') }
                          
    class << self
      ##
      # @return [RDF::URI] uri with lexical representation 
      #   'http://www.w3.org/ns/ldp#Resource'
      #
      # @see http://www.w3.org/TR/ldp/#dfn-linked-data-platform-resource
      def to_uri 
        RDF::URI 'http://www.w3.org/ns/ldp#Resource'
      end

      ##
      # Retrieves the correct interaction model from the Link headers.
      #
      # Headers are handled intelligently, e.g. if a client sends a request with
      # Resource, RDFSource, and BasicContainer headers, the server gives a 
      # BasicContainer. An error is thrown if the headers contain conflicting 
      # types (i.e. NonRDFSource and another Resource class).
      #
      # @param [String] link_header  a string containing Link headers from an 
      #   HTTP request (Rack env)
      # 
      # @return [Class] a subclass of {RDF::LDP::Resource} matching the 
      #   requested interaction model; 
      def interaction_model(link_header)
        models = LinkHeader.parse(link_header)
                 .links.select { |link| link['rel'].downcase == 'type' }
                 .map { |link| link.href }

        return RDFSource if models.empty?
        match = INTERACTION_MODELS.keys.reverse.find { |u| models.include? u }
        
        if match == RDF::URI('http://www.w3.org/ns/ldp#NonRDFSource')
          raise NotAcceptable if 
            models.include?(RDF::URI('http://www.w3.org/ns/ldp#RDFSource')) ||
            models.include?(RDF::URI('http://www.w3.org/ns/ldp#DirectContainer')) ||
            models.include?(RDF::URI('http://www.w3.org/ns/ldp#IndirectContainer')) ||
            models.include?(RDF::URI('http://www.w3.org/ns/ldp#BasicContainer'))
        end

        INTERACTION_MODELS[match]
      end
    end

    ##
    # @return [Boolean] whether this is an ldp:Resource
    def ldp_resource?
      true
    end

    ##
    # @return [Boolean] whether this is an ldp:Container
    def container?
      false
    end

    ##
    # @return [Boolean] whether this is an ldp:NonRDFSource
    def non_rdf_source?
      false
    end

    ##
    # @return [Boolean] whether this is an ldp:RDFSource
    def rdf_source?
      false
    end

    ##
    # Runs the request and returns the object's desired HTTP response body, 
    # conforming to the Rack interfare. 
    #
    # @see http://www.rubydoc.info/github/rack/rack/master/file/SPEC#The_Body 
    #   for Rack body documentation
    def to_response
      []
    end
    alias_method :each, :to_response

    ##
    # Build the response for the HTTP `method` given.
    # 
    # The method passed in is symbolized, downcased, and sent to `self` with the
    # other three parameters.
    #
    # Request methods are expected to return an Array appropriate for a Rack
    # response; to return this object (e.g. for a sucessful GET) the response 
    # may be `[status, headers, self]`.
    #
    # If the method given is unimplemented, we understand it to require an HTTP 
    # 405 response, and throw the appropriate error.
    #
    # @param [#to_sym] method  the HTTP request method of the response; this 
    #   message will be downcased and sent to the object.
    # @param [Fixnum] status  an HTTP response code; this status should be sent 
    #   back to the caller or altered, as appropriate.
    # @param [Hash<String, String>] headers  a hash mapping HTTP headers 
    #   built for the response to their contents; these headers should be sent 
    #   back to the caller or altered, as appropriate.
    # @param [] env  the Rack env for the request
    #
    # @return [Array<Fixnum, Hash<String, String>, #each] a new Rack response 
    #   array.
    def request(method, status, headers, env)
      begin
        send(method.to_sym.downcase, status, headers, env)
      rescue NoMethodError, NotImplementedError => e
        raise MethodNotAllowed, method
      end
    end

    private

    ##
    # Generate response for GET requests. Returns existing status and headers, 
    # with `self` as the body.
    def get(status, headers, env)
      [status, headers, self]
    end

    ##
    # Generate response for HEAD requsets. Adds appropriate headers and returns 
    # an empty body.
    def head(status, headers, env)
      [status, headers, []]
    end

    ##
    # Generate response for HEAD requsets. Adds appropriate headers and returns 
    # an empty body.
    def options(status, headers, env)
      [status, headers, []]
    end
  end
end