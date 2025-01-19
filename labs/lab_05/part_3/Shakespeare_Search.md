# Download mapping for index
sudo wget http://media.sundog-soft.com/es8/shakes-mapping.json


curl -H "Content-Type: application/json" -XPUT 127.0.0.1:9200/shakespeare --data-binary @shakes-mapping.json

# Download shakespeare data
sudo wget http://media.sundog-soft.com/es8/shakespeare_8.0.json

# Index data to Elasticsearch
curl -H "Content-Type: application/json" -XPUT '127.0.0.1:9200/shakespeare/_bulk' --data-binary @shakespeare_8.0.json

# Try searching a phrase

curl -H "Content-Type: application/json" -XGET '127.0.0.1:9200/shakespeare/_search?pretty' -d '
{
"query" : {
"match_phrase" : {
"text_entry" : "to be or not to be"
}
}
}' 