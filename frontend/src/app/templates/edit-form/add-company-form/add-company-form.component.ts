import { Component } from '@angular/core';
import { Router } from '@angular/router';

import { CompaniesService } from '../../../deck-api/companies.service';
import { EditFormCommunicatorService, AppliedForm } from '../edit-form-communicator.service';

import { AddCompanyForm, Company } from '../../../models/company';

@Component({
    selector: 'app-add-company-form',
    templateUrl: './add-company-form.component.html',
    styleUrls: ['./add-company-form.component.css']
})
export class AddCompanyFormComponent {

    form: AddCompanyForm;

    constructor(
        private editFormCommunicatorService: EditFormCommunicatorService,
        private companiesService: CompaniesService,
        private router: Router
    ) {
        this.form = new AddCompanyForm();
    }

    submitNewCompany() {
        if (!this.form.valid()) { return; }

        this.companiesService.addCompany(this.form).subscribe((company: Company) => {
            this.editFormCommunicatorService.setAppliedForm(AppliedForm.AddCompany);
            this.editFormCommunicatorService.closeForm();
            this.router.navigate(['/companies/' + company.id]);
        });
    }

}
