import { Component, OnInit } from '@angular/core';

import { HealthService } from '../../deck-api/health.service';
import { ThemeService } from '../../theme.service';

@Component({
    selector: 'app-server-down',
    templateUrl: './server-down.component.html',
    styleUrls: ['./server-down.component.css']
})
export class ServerDownComponent implements OnInit {

    constructor(
        private healthService: HealthService,
        private themeService: ThemeService
    ) { }

    ngOnInit() {
        this.healthService.subscribeHealthCheck();
    }

}
