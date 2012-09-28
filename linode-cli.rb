#!/usr/bin/env ruby

require 'linode'
require 'optparse'

# Where to put this...
class Array
    def rest
        self[1..-1]
    end
end

def l
    if not ENV.has_key?('LINODE_API_KEY')
        puts "You define environment variable LINODE_API_KEY"
        exit 1
    end
    $l ||= Linode.new(:api_key => ENV['LINODE_API_KEY'])
end

class Env
    # Populate with usage string in subclass
    @usage = nil

    def self.go(params)
    end

    def self.usage
        puts "Usage: #{@usage}"
    end
end

class SummaryEnv < Env
    def self.go(params)
        puts "linode"
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

class DNSUtil
    def self.getDomainNames
        l.domain.list.map {|domain| domain.domain}
    end
    
    def self.getDomainId(domain)
        (l.domain.list.detect {|res| res.domain == domain}).domainid
    end
    
    def self.getResourceId(domainid, type, name)
        (l.domain.resource.list(:domainid => domainid).detect {|res|
            res.type.downcase == type.to_s and res.name == name
        }).resourceid
    end
    
    def self.getDomainRecords(domain_id)
        records = {}
        for type in DNSRecord::RecordTypes
            records[type] = []
        end
        
        l.domain.resource.list(:domainid => domain_id).each do |record|
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
            domains_raw = l.domain.list
            domains_raw.each do |domain_raw|
                domains[domain_raw.domain] = getDomainRecords(domain_raw.domainid)
            end
        end

        return domains
    end
end

class DNSList < Env
    def self.go(params)
        puts 'All accessible domains:'

        DNSUtil::getDomainNames.each do |domain|
            puts '  ' + domain
        end
    end
end

class DNSShow < Env
    @usage = 'dns show <type?> <domain?>'
    
    def self.go(params)
        if params.size == 2
            type = params[0].downcase.to_sym
            domain = params[1]
            
            unless DNSRecord::RecordTypes.include? type
                puts "Invalid DNS record type: #{type}"
                exit 1
            end
        elsif params.size == 1
            if DNSRecord::RecordTypes.include? params[0].downcase.to_sym
                type = params[0].downcase.to_sym
                domain = :all
            else
                type = :all
                domain = params[0]
            end
        elsif params.size == 0
            type = :all
            domain = :all
        else
            usage
            exit 1
        end
        
        DNSUtil::getRecords(domain).each do |domain, records|
            if type == :all
                records_to_show =
                    records[:a] +
                    records[:aaaa] +
                    records[:cname] +
                    records[:mx] +
                    records[:txt]
                
                unless records_to_show.empty?
                    puts "Showing all records for #{domain}"
                end
            else
                records_to_show = records[type]
                
                unless records_to_show.empty?
                    puts "Showing #{type.upcase} records for #{domain}"
                end
            end
            
            records_to_show.each do |r|
                puts '  ' + r.to_s
            end
        end
    end
end

class DNSAdd < Env
    def self.go(params)
        @usage = 'dns add <domain> <host> <ip>'
        
        unless params.size == 3
            usage
            exit 1
        end
        
        domain = params[0]
        host = params[1]
        ip = params[2]
        
        domainid = DNSUtil::getDomainId domain
        
        l.domain.resource.create(
            :domainid => domainid,
            :type => 'a',
            :name => host,
            :target => ip
        )
    end
end

class DNSDel < Env
    def self.go(params)
        @usage = 'dns del <domain> <host>'
        
        unless params.size == 2
            usage
            exit 1
        end
        
        domain = params[0]
        host = params[1]
        
        domainid = DNSUtil::getDomainId domain
        resourceid = DNSUtil::getResourceId domainid, :a, host
        
        l.domain.resource.delete(
            :domainid => domainid,
            :resourceid => resourceid
        )
    end
end

class DNSEnv < Env
    Commands = {
        :list => DNSList,
        :show => DNSShow,
        :add => DNSAdd,
        :del => DNSDel
    }

    @usage = 'linode dns <list, show> ...'

    def self.go(params)
        if params.size > 0
            cmd = params[0].downcase.to_sym

            unless Commands.include? cmd
                puts "Invalid DNS query command: #{cmd}"
                usage
                exit 1
            end
        else
            cmd = :list
        end

        Commands[cmd]::go params.rest
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

ENVS[env]::go ARGV.rest
