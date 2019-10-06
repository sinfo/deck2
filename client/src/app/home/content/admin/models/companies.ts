import { Link } from './link';
import { Event } from 'app/models/event';
import { Company, Participation } from 'app/models/company';

export class Companies {
    all: Company[];
    withLink: {
        valid: Company[];
        invalid: Company[];
    };
    withoutLink: Company[];

    constructor() {
        this.all = [] as Company[];
        this.withLink = {
            valid: [] as Company[],
            invalid: [] as Company[]
        };
        this.withoutLink = [] as Company[];
    }

    private fillLinks(companies: Company[], links: Link[]): {
        withLink: { valid: Company[], invalid: Company[] },
        withoutLink: Company[]
    } {
        const result = {
            withLink: { valid: <Company[]>[], invalid: <Company[]>[] },
            withoutLink: <Company[]>[]
        };

        for (const company of companies) {
            const filtered = <Link[]>links.filter(l => l.companyId === company.id);

            if (!filtered.length) {
                result.withoutLink.push(company);
                continue;
            }

            const link = new Link(filtered[0]);
            const newCompany = new Company();

            newCompany.id = company.id;
            newCompany.img = company.img;
            newCompany.name = company.name;
            newCompany.currentParticipation =
                company.currentParticipation
                    ? company.currentParticipation
                    : Participation.getFromEdition(company.participations, filtered[0].edition);
            newCompany.link = link;

            if (link.valid) {
                result.withLink.valid.push(newCompany);
            } else {
                result.withLink.invalid.push(newCompany);
            }
        }

        return result;
    }

    // TODO why is it unused
    update(companies: Company[], links: Link[]) {
        if (!links.length) { return; }
        this.updateCompanies(companies, links[0].edition);
        this.updateLinks(links);
    }

    updateCompanies(companies: Company[], edition: String) {
      this.all = <Company[]>companies.filter(c => Company.filter(c, edition));
    }

    updateLinks(links: Link[]) {
        const result = this.fillLinks(this.all, links);
        this.withLink = result.withLink;
        this.withoutLink = result.withoutLink;
    }
}
