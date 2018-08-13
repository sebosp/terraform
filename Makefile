jsonify:
	rm -rf ./vars_json && ./jsonify.sh vars ./vars_json
terraform:
	jsonnet -J lib -J vars_json -A env=$$TARGET_ENV --multi . iam.jsonnet
all: jsonify terraform
# vim: noet
