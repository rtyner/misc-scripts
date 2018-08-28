#!/bin/bash

#######################################################################################
# Author: Rusty Tyner                                                                 #
# Date: 2/18/18                                                                       #
# Purpose: To retrieve shard health of elasticsearch cluster and report if red        #
#######################################################################################

# curl the REST API of your elasticsearch server
curl http://ELASTIC_SEARCH_IP:9200/_cluster/health > ~/elastic_health.txt
if cat ~/elastic_health.txt | grep red/|yellow >> /dev/null
then
	mail -s "Elastic Search Health Degraded" EMAIL_ADDRESS_HERE <<< Your elasticsearch cluster needs some help. Please check that status here: http://ELASTIC_SEARCH_IP:9200
fi
