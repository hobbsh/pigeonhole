require 'json'

module HighCharts
  def self.alert_frequency(incidents)
    incidents.map { |incident|
      name = incident['entity'].gsub(/.bulletproof.net$/, '')
      # Truncate long check names by removing everything after and including the second -
      name << ":#{incident['check'].gsub(/-.+(-.+)/, '')}" unless incident['check'].nil?
      {
        :name => name,
        :data => [incident['count']]
      }
    }.slice(0, 50).to_json
  end

  def self.alert_response(opts)
    return {} unless opts[:incidents]
    if opts[:aggregated]
      ack_data, resolve_data = %w(ack resolve).map { |type|
        opts[:aggregated].map { |i|
          [i['time'] * 1000, i["mean_#{type}"]]
        }
      }.compact.sort
      ack_name = 'Average time until acknowledgement of alert'
      resolve_name = 'Average time until alert was resolved'
    else
      ack_data, resolve_data = %w(ack resolve).map { |type|
        opts[:incidents].map { |i|
          {
            name: i['incident_key'],
            x: i['alert_time'] * 1000,
            y: i["time_to_#{type}"]
          }
        }.compact.sort_by { |k| k[:x] }
      }
      ack_name = 'Time until acknowledgement of alert'
      resolve_name = 'Time until alert was resolved'
    end

    count_data = opts[:count].map { |i|
      [i['time'] * 1000, i['count']]
    }.compact.sort

    [
      {
        :name => "Number of alerts per #{opts[:count_group_by]}",
        :data => count_data,
        :dashStyle => 'shortdot'
      }, {
        :name => ack_name,
        :data => ack_data,
        :yAxis => 1,
        :tooltip => {
          :valueSuffix => 'min'
        }
      }, {
        :name => resolve_name,
        :data => resolve_data,
        :yAxis => 1,
        :tooltip => {
          :valueSuffix => 'min'
        }
      }
    ].to_json
  end
end