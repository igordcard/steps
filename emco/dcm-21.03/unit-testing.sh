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
