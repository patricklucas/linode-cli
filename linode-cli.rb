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
    def initialize(record)
        @record = record
    end

    def type
        @record.type.downcase.to_sym
    end
end

class DNSRecordA < DNSRecord
    def to_s
        unless @record.name.empty?
            "A      #{@record.name}  #{@record.target}"
        else
            "A      #{@record.target}"
        end
    end
end

class DNSRecordAAAA < DNSRecord
    def to_s
        unless @record.name.empty?
            "AAAA   #{@record.name}  #{@record.target}"
        else
            "AAAA   #{@record.target}"
        end
    end
end

class DNSRecordCNAME < DNSRecord
    def to_s
        "CNAME  #{@record.name}  #{@record.target}"
    end
end

class DNSRecordMX < DNSRecord
    def to_s
        "MX     #{@record.target}  #{@record.priority}"
    end
end

class DNSRecordTXT < DNSRecord
    def to_s
        unless @record.name.empty?
            "TXT    #{@record.name}  #{@record.target}"
        else
            "TXT    #{@record.target}"
        end
    end
end

class DNSShow < LinodeEnv
    RecordTypes = {
        :a     => DNSRecordA,
        :aaaa  => DNSRecordAAAA,
        :cname => DNSRecordCNAME,
        :mx    => DNSRecordMX,
        :txt   => DNSRecordTXT
    }

    def getDomainId(domain)
        ($l.domain.list.detect {|res| res.domain == domain}).domainid
    end

    def createDNSRecord(record)
        RecordTypes[record.type.downcase.to_sym].new record
    end

    def getRecords(domain)
        records = []

        domainid = getDomainId domain

        $l.domain.resource.list(:domainid => domainid).each do |record|
            records << createDNSRecord(record)
        end

        return records
    end

    def go(params)
        if params.size == 2
            type = params[0].downcase.to_sym
            domain = params[1]
        elsif params.size == 1
            type = :all
            domain = params[0]
        else
            puts 'Usage: linode dns show <type?> <domain>'
            exit 1
        end

        unless type == :all
            unless RecordTypes.include? type
                puts "Invalid DNS record type: #{type}"
                exit 1
            end

            (getRecords(domain).select {|r| r.type == type}).each do |r|
                puts r
            end
        else
            getRecords(domain).each do |r|
                puts r
            end
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
