import { Component, OnInit, Output, EventEmitter } from '@angular/core';

import { HttpResponse, HttpEventType } from '@angular/common/http';
import { NgbModal, ModalDismissReasons } from '@ng-bootstrap/ng-bootstrap';


import { Venue } from '../../models/venue';
import { SponsorsService } from '../../../../services/sponsors.service';
import { AuthService } from '../../../../services/auth.service';

@Component({
  selector: 'app-upload',
  templateUrl: './upload.component.html',
  styleUrls: ['./upload.component.css']
})
export class UploadComponent implements OnInit {

  @Output() newVenue = new EventEmitter<Venue>();

  venue: Venue;

  error: {
    type: String,
    message: String
  };
  closeResult: string;
  selectedFiles: FileList;
  currentFileUpload: File;
  progress: { percentage: number } = { percentage: 0 };

  loadingSrc: String = 'assets/img/loading.gif';

  constructor(
    private sponsorsService: SponsorsService,
    private modalService: NgbModal,
    private authService: AuthService
  ) { }

  ngOnInit() {
  }

  selectFile(event) {
    this.selectedFiles = event.target.files;
  }

  upload() {
    this.error = undefined;
    this.progress.percentage = 0;
    this.currentFileUpload = this.selectedFiles.item(0);
    this.sponsorsService.uploadVenueImage(this.currentFileUpload).subscribe(
      event => {
        if (event.type === HttpEventType.UploadProgress) {
          this.progress.percentage = Math.round(100 * event.loaded / event.total);
        } else if (event instanceof HttpResponse) {
          const venue: Venue = <Venue>JSON.parse(<string>event.body);
          this.updateVenue(venue);
        }
      },
      error => {
        if (error.status === 401) {
          this.authService.logout();
          this.error = {
            type: 'fatal',
            message: 'Could not upload. Authentication failed. Please try to login.'
          };
        } else {
          this.error = {
            type: 'unknown',
            message: 'Upload failed.'
          };
        }
      }
    );
    this.selectedFiles = undefined;
  }

  updateVenue(venue: Venue) {
    venue.image = `${venue.image}?t=${new Date().getTime()}`;
    this.venue = venue;
    this.newVenue.emit(venue);
  }

  open(content) {
    this.modalService.open(content).result.then((result) => {
      this.closeResult = `Closed with: ${result}`;
    }, (reason) => {
      this.closeResult = `Dismissed ${this.getDismissReason(reason)}`;
    });
  }

  close(reason: string) {
    this.modalService.dismissAll(reason);
  }

  private getDismissReason(reason: any): string {
    if (reason === ModalDismissReasons.ESC) {
      return 'by pressing ESC';
    } else if (reason === ModalDismissReasons.BACKDROP_CLICK) {
      return 'by clicking on a backdrop';
    } else {
      return `with: ${reason}`;
    }
  }

}
