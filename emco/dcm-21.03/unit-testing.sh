# ===========================
# Testing and Validation
# REF(TESTING-VALIDATION)

# install mockery for generating mocks
apt-get install mockery

# install ginkgo dependencies
go get github.com/onsi/ginkgo/ginkgo
go get github.com/onsi/gomega/...

# initialize package's ginkgo
ginkgo bootstrap

# create new test file apply_test.go
ginkgo generate apply # apply is the name

# check coverage for package:
go test -cover
ginkgo -cover

# running
ginkgo
go test
go test -run TestCreateLogicalCloud
