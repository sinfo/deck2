package models

import (
	"testing"

	"go.mongodb.org/mongo-driver/bson"
)

func TestCompanyRepWorkRoleIsOptional(t *testing.T) {
	withRole, err := bson.Marshal(CompanyRep{WorkRole: "Talent Acquisition Manager"})
	if err != nil {
		t.Fatal(err)
	}
	var decoded CompanyRep
	if err := bson.Unmarshal(withRole, &decoded); err != nil {
		t.Fatal(err)
	}
	if decoded.WorkRole != "Talent Acquisition Manager" {
		t.Fatalf("workRole = %q", decoded.WorkRole)
	}

	withoutRole, err := bson.Marshal(CompanyRep{})
	if err != nil {
		t.Fatal(err)
	}
	decoded = CompanyRep{}
	if err := bson.Unmarshal(withoutRole, &decoded); err != nil {
		t.Fatal(err)
	}
	if decoded.WorkRole != "" {
		t.Fatalf("missing workRole = %q", decoded.WorkRole)
	}
}
