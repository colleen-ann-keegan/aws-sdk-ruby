module AwsSdkCodeGenerator
  class ClientOperationList

    include Enumerable

    def initialize(options)
      api = options.fetch(:api)
      examples = options.fetch(:examples, {})
      module_name = options.fetch(:module_name)
      client_examples = options.fetch(:client_examples, {})
      @operations = api['operations'].inject([]) do |ops, (name, operation)|
        method_name = Underscore.underscore(name)
        async_client = options[:async_client] || false
        es_output = AwsSdkCodeGenerator::Helper.eventstream_output?(operation, api)
        es_input = AwsSdkCodeGenerator::Helper.eventstream_input?(operation, api)
        if async_client
          ops << Operation.new(
            name: method_name,
            documentation: ClientOperationDocumentation.new(
              name: name,
              module_name: module_name,
              method_name: method_name,
              operation: operation,
              api: api,
              examples: examples,
              client_examples: client_examples[method_name] || [],
              async_client: true
            ).to_s,
            streaming: AwsSdkCodeGenerator::Helper.operation_streaming?(operation, api),
            eventstream_output: es_output,
            eventstream_input: es_input
          )
        elsif !!es_input
          # skip this operation for normal client
          # current don't support streaming input for http1.1
          raise "input event streaming currently not supported for non h2 services"
        else
          ops << Operation.new(
            name: method_name,
            documentation: ClientOperationDocumentation.new(
              name: name,
              module_name: module_name,
              method_name: method_name,
              operation: operation,
              api: api,
              examples: examples,
              client_examples: client_examples[method_name] || [],
              async_client: false
            ).to_s,
            streaming: AwsSdkCodeGenerator::Helper.operation_streaming?(operation, api),
            eventstream_output: es_output,
            eventstream_input: false,
          )
        end
        ops
      end
    end

    # @return [Enumerable<Operation>]
    def each(&block)
      @operations.each(&block)
    end

    class Operation

      def initialize(options)
        @name = options.fetch(:name)
        @documentation = options.fetch(:documentation)
        @streaming = options.fetch(:streaming)
        @eventstream_output = !!options.fetch(:eventstream_output)
        @eventstream_input = !!options.fetch(:eventstream_input)
        @output_eventstream_member = @eventstream_output ?
          options.fetch(:eventstream_output) : nil
        @input_eventstream_member = @eventstream_input ?
          options.fetch(:eventstream_input) : nil
        @bidirectional = @eventstream_output && @eventstream_input
      end

      # @return [String]
      attr_reader :name

      # @return [String, nil]
      attr_reader :documentation

      # @return [Boolean]
      attr_reader :eventstream_input

      # @return [Boolean]
      attr_reader :eventstream_output

      # @return [String]
      attr_reader :input_eventstream_member

      # @return [String]
      attr_reader :output_eventstream_member

      # @return [Boolean]
      attr_reader :bidirectional

      def block_option
        if @streaming
          ", &block"
        end
      end

    end
  end
end
