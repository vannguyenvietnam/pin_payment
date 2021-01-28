module PinPayment
  class Transfer < Base

    attr_accessor :description, :amount, :currency, :recipient, :token, :status, :paid_at, :total_debits, :total_credits
    protected     :description=, :amount=, :currency=, :recipient=, :token=, :status=, :paid_at=, :total_debits=, :total_credits=

    # Uses the pin API to create a transfer.
    #
    # @param [Hash] transfer_data
    # @option transfer_data [String] :description *required*
    # @option transfer_data [String] :amount *required*
    # @option transfer_data [String] :currency *required* (Currenly only AUD is supported)
    # @option transfer_data [String] :recipient *required* a token for a stored recipient
    # @return [PinPayment::Transfer]
    def self.create transfer_data
      attributes = self.attributes - [:token] # fix attributes allowed by POST API
      options    = parse_options_for_request(attributes, transfer_data)
      response   = post(URI.parse(PinPayment.api_url).tap{|uri| uri.path = '/1/transfers' }, options)
      new(response.delete('token'), response)
    end

    # Fetches all of your transfers using the pin API.
    #
    # @param [Hash] request_options *optional*
    # @option request_options [Integer] :page (pagination page)
    # @option request_options [String] :query (Return only transfers whose token, description, amount or recipient details match the supplied query.)
    # @option request_options [String] :start_date (Return only transfers created on or after this date (e.g. 2012/12/25).)
    # @option request_options [String] :end_date (Return only transfers created before this date (e.g. 2013/12/25).)
    # @option request_options [String] :sort (The field used to sort the transfers (only option: paid_at). Default value is paid_at.)
    # @option request_options [Integer] :direction (The direction in which to sort the transfers (1 for ascending or -1 for descending). Default value is 1.)
    # @return [Array<PinPayment::Transfer>]
    # TODO: pagination
    def self.all request_options = {}
      response = get(URI.parse(PinPayment.api_url).tap{|uri| uri.path = '/1/transfers' }, request_options)
      response.map{|x| new(x.delete('token'), x) }
    end

    # Fetches a transfer using the pin API.
    #
    # @param [String] token the recipient token
    # @return [PinPayment::Transfer]
    def self.find token
      response = get(URI.parse(PinPayment.api_url).tap{|uri| uri.path = "/1/transfers/#{token}" })
      new(response.delete('token'), response)
    end

    def line_items
      response = self.class.get(URI.parse(PinPayment.api_url).tap{|uri| uri.path = "/1/transfers/#{token}/line_items" })
      response.map{|hash| LineItem.new(hash.delete('token')) }
    end

    protected

    def self.attributes
      [:token, :description, :amount, :currency, :recipient, :status, :paid_at, :total_debits, :total_credits]
    end

    class LineItem < Base
      attr_accessor :type, :object, :amount, :token
      protected     :type=, :object=, :amount=, :token=

      protected

      def self.attributes
        [:token, :type, :object, :amount, :recipient]
      end
    end

  end
end
