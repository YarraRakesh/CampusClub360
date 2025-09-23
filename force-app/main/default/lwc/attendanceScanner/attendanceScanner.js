import { LightningElement, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import JSQR from '@salesforce/resourceUrl/JSQR';
import getMeetings from '@salesforce/apex/AttendanceController.getMeetings';
import findStudentByBarcode from '@salesforce/apex/AttendanceController.findStudentByBarcode';
import createAttendance from '@salesforce/apex/AttendanceController.createAttendance';

export default class AttendanceScanner extends LightningElement {
    @track meetingOptions = [];
    selectedMeeting = '';
    selectedMeetingName = '';
    isScanning = false;
    jsqrLoaded = false;
    stream = null;
    @track scannedList = [];

    get buttonLabel() {
        return this.isScanning ? 'Stop Scanning' : 'Start Scanning';
    }

    renderedCallback() {
        if (this.jsqrLoaded) return;

        loadScript(this, JSQR)
            .then(() => {
                this.jsqrLoaded = true;
                return getMeetings();
            })
            .then(result => {
                // Map meetings; label shows name (you can add date if desired)
                this.meetingOptions = result.map(m => ({ label: m.Name, value: m.Id }));
            })
            .catch(error => {
                console.error('Error loading JSQR or fetching meetings', error);
                this.showToast('Load Error', 'Could not load scanner or meetings', 'error');
            });
    }

    handleMeetingChange(event) {
        this.selectedMeeting = event.detail.value;
        const meeting = this.meetingOptions.find(m => m.value === this.selectedMeeting);
        this.selectedMeetingName = meeting ? meeting.label : '';
    }

    async toggleScan() {
        if (!this.isScanning) {
            if (!this.selectedMeeting) {
                this.showToast('Select Meeting', 'Please select a meeting first.', 'warning');
                return;
            }
            await this.startCamera();
            this.isScanning = true;
            this.scanLoop();
        } else {
            this.stopCamera();
            this.isScanning = false;
        }
    }

    async startCamera() {
        const video = this.template.querySelector('video');
        try {
            this.stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
            video.srcObject = this.stream;
            await video.play();
        } catch (err) {
            console.error('Camera error', err);
            this.showToast('Camera Error', 'Cannot access camera. Allow permission or try a different browser.', 'error');
        }
    }

    stopCamera() {
        if (this.stream) {
            this.stream.getTracks().forEach(t => t.stop());
            this.stream = null;
        }
    }

    disconnectedCallback() {
        // ensure camera is stopped when component removed
        this.stopCamera();
    }

    async scanLoop() {
        const video = this.template.querySelector('video');
        const canvas = this.template.querySelector('canvas');
        if (!canvas) return;
        const ctx = canvas.getContext('2d');

        const loop = async () => {
            if (!this.isScanning) return;
            if (video.readyState === video.HAVE_ENOUGH_DATA) {
                canvas.width = video.videoWidth;
                canvas.height = video.videoHeight;
                ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
                const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);

                const code = window.jsQR ? window.jsQR(imageData.data, canvas.width, canvas.height) : null;
                if (code && code.data) {
                    await this.handleDetected(code.data);
                    await this.sleep(1200); // debounce
                }
            }
            requestAnimationFrame(loop);
        };
        requestAnimationFrame(loop);
    }

    sleep(ms) {
        return new Promise(res => setTimeout(res, ms));
    }

    async handleDetected(barcodeValue) {
        try {
            const student = await findStudentByBarcode({ barcodeValue });
            if (!student) {
                this.showToast('Not Found', `No student found for code: ${barcodeValue}`, 'error');
                // show in recent list as error
                this.prependScan({ key: barcodeValue + '-' + Date.now(), name: `Unknown (${barcodeValue})`, time: new Date().toLocaleString(), cssClass: 'error' });
                return;
            }

            // call server to create attendance (or return existing)
            const result = await createAttendance({ studentId: student.Id, meetingId: this.selectedMeeting });
            const att = result.attendance;
            const wasNew = result.isNew;

            if (wasNew) {
                this.showToast('Attendance Recorded', `${att.Student__r ? att.Student__r.Name : student.Name} checked in successfully.`, 'success');
            } else {
                this.showToast('Duplicate', `${att.Student__r ? att.Student__r.Name : student.Name} is already checked in for this meeting.`, 'warning');
            }

            this.prependScan({
                key: att.Id,
                name: att.Student__r ? att.Student__r.Name : student.Name,
                time: new Date(att.Check_In_Time__c).toLocaleString(),
                cssClass: wasNew ? 'success' : 'duplicate'
            });

        } catch (err) {
            console.error('Error processing scan', err);
            this.showToast('Error', 'An error occurred while processing the scan (or) Attendance not allowed outside Club timings (10 AM – 3 PM, Mon–Sat, excluding holidays', 'error');
        }
    }

    prependScan(scanObj) {
        this.scannedList = [scanObj, ...this.scannedList].slice(0, 10);
    }

    showToast(title, message, variant='info') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}