import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';

import { MeService } from '../../../deck-api/me.service';
import { SpeakersService } from '../../../deck-api/speakers.service';
import { PostsService } from '../../../deck-api/posts.service';

import { Member } from '../../../models/member';
import { Speaker } from '../../../models/speaker';
import { Post } from '../../../models/post';

@Component({
    selector: 'app-template-speakers27',
    templateUrl: './template-speakers27.component.html',
    styleUrls: ['./template-speakers27.component.css']
})
export class TemplateSpeakers27Component implements OnInit {

    speaker: Speaker;
    me: Member;
    post: Post;

    constructor(
        private route: ActivatedRoute,
        private meService: MeService,
        private speakersService: SpeakersService,
        private postsService: PostsService,
    ) { }

    ngOnInit() {
        const speakerID = this.route.snapshot.params['speakerID'];
        const postID = this.route.snapshot.params['postID'];

        this.speakersService.getSpeaker(speakerID).subscribe((speaker: Speaker) => { this.speaker = speaker; });
        this.meService.getMe().subscribe((member: Member) => { this.me = member; });
        this.postsService.getPost(postID).subscribe((post: Post) => { this.post = post; });
    }

}
