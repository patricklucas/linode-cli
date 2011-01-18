#!/usr/bin/env ruby

require 'linode'
require 'optparse'

API_KEY = 'rxAbs8sQ4kZ0HVzC1BDDgIGBKNuuhvGckoIIkgUCnuLiHiCymSrwmKYuCXQxLaMf'

def l
    $l ||= Linode.new(:api_key => API_KEY)
end

class Env
    def self.go(params)
    end
end

class SummaryEnv < Env
    def self.go(params)
        puts "linode"
    end
end

class DNSEnv < Env
    Commands = [
        :show
    ]

    def self.go(params)
        cmd = params[0].downcase.to_sym

        case cmd
        when :show
            DNSShow::go params[1, params.length - 1]
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

class DNSShow < Env
    def self.getDomainId(domain)
        (l().domain.list.detect {|res| res.domain == domain}).domainid
    end
    
    def self.getDomainRecords(domain_id)
        records = {}
        for type in DNSRecord::RecordTypes
            records[type] = []
        end
        
        l().domain.resource.list(:domainid => domain_id).each do |record|
            dns_record = DNSRecord.new record
            records[dns_record.type] << dns_record
        end
        
        return records
    end

    def self.getRecords(domain)
        domains = {}

        unless domain == :all
            domain_id = getDomainId domain
            domains[domain] = getDomainRecords domain_id
        else
            domains_raw = l().domain.list
            domains_raw.each do |domain_raw|
                domains[domain_raw.domain] = getDomainRecords(domain_raw.domainid)
            end
        end

        return domains
    end
    
    def self.go(params)
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
        elsif params.size == 0
            type = :all
            domain = :all
        else
            puts 'Usage: linode dns show <type?> <domain>'
            exit 1
        end
        
        getRecords(domain).each do |domain, records|
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
                puts '  ' + r.to_s
            end
        end
    end
end

class LinodeEnv < Env
    def self.go(params)
        puts "whee"
    end
end

ENVS = {
    :summary => SummaryEnv,
    :dns => DNSEnv,
    :l => LinodeEnv
}

env = ARGV[0] && ARGV[0].downcase.to_sym || :summary

unless ENVS.include? env
    puts "Not valid env"
    exit 1
end

ENVS[env]::go ARGV[1, ARGV.length - 1]
