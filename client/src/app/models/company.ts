export class Company {
    id: String;
    name: String;
    description: String;
    imgs: CompanyImages;
    site: String;
    employers: String[];
    billingInfo: CompanyBillingInfo;
    participations: CompanyParticipation[];
}

export class CompanyImages {
    internal: String;
    public: String;
}

export class CompanyBillingInfo {
    name: String;
    address: String;
    tin: String;
}

export class CompanyParticipation {
    event: Number;
    member: String;
    status: String;
    communications: String[]
    subscribers: String[];
    billing: String;
    package: String;
    confirmed: Date;
    partner: Boolean;
    notes: String;
}
