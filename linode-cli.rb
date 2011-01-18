#!/usr/bin/env ruby

require 'linode'
require 'optparse'

ENVS = [
    :dns
]

API_KEY = 'rxAbs8sQ4kZ0HVzC1BDDgIGBKNuuhvGckoIIkgUCnuLiHiCymSrwmKYuCXQxLaMf'

class LinodeEnv
end

class DNS < LinodeEnv
    Commands = [
        :show
    ]

    def go(params)
        cmd = params[0].to_sym

        case cmd
        when :show
            DNSShow.new.go params[1, params.length - 1]
        end
    end
end

class DNSRecord
    RecordTypes = [:a, :aaaa, :cname, :mx, :txt]
    
    def initialize(record)
        @record = record
    end

    def type
        @record.type.downcase.to_sym
    end
    
    def to_s
        case type
        when :a
            unless @record.name.empty?
                "A      #{@record.name}  #{@record.target}"
            else
                "A      #{@record.target}"
            end
        when :aaaa
            unless @record.name.empty?
                "AAAA   #{@record.name}  #{@record.target}"
            else
                "AAAA   #{@record.target}"
            end
        when :cname
            "CNAME  #{@record.name}  #{@record.target}"
        when :mx
            "MX     #{@record.target}  #{@record.priority}"
        when :txt
            unless @record.name.empty?
                "TXT    #{@record.name}  #{@record.target}"
            else
                "TXT    #{@record.target}"
            end
        end
    end
end

class DNSShow < LinodeEnv
    def getDomainId(domain)
        ($l.domain.list.detect {|res| res.domain == domain}).domainid
    end

    def getRecords(domain)
        records = {}
        for type in DNSRecord::RecordTypes
            records[type] = []
        end

        domainid = getDomainId domain

        $l.domain.resource.list(:domainid => domainid).each do |record|
            dns_record = DNSRecord.new record
            records[dns_record.type] << dns_record
        end

        return records
    end
    
    def go(params)
        if params.size == 2
            type = params[0].downcase.to_sym
            domain = params[1]
            
            unless DNSRecord::RecordTypes.include? type
                puts "Invalid DNS record type: #{type}"
                exit 1
            end
        elsif params.size == 1
            type = :all
            domain = params[0]
        else
            puts 'Usage: linode dns show <type?> <domain>'
            exit 1
        end
        
        records = getRecords(domain)
        
        if type == :all
            records_to_show =
                records[:a] +
                records[:aaaa] +
                records[:cname] +
                records[:mx] +
                records[:txt]
            
            puts "Showing all records for #{domain}"
        else
            records_to_show = records[type]
            
            puts "Showing #{type.upcase} records for #{domain}"
        end

        records_to_show.each do |r|
            puts r
        end
    end
end

def do_summary
    puts "linode"
end

if ARGV.size == 0
    do_summary
    exit
end

env = ARGV[0].to_sym

unless ENVS.include? env
    puts "Not valid env"
    exit 1
end

$l = Linode.new(:api_key => API_KEY)

if env == :dns
    DNS.new.go ARGV[1, ARGV.length - 1]
end
