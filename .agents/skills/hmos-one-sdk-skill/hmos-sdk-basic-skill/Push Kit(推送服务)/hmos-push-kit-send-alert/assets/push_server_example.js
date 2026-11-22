const axios = require('axios');

class PushKitNotificationSender {
    constructor(projectId, authorizationToken) {
        this.projectId = projectId;
        this.authorizationToken = authorizationToken;
        this.baseUrl = 'https://push-api.cloud.huawei.com/v3';
    }

    async sendNotification({
        tokens,
        title,
        body,
        category = 'MARKETING',
        actionType = 0,
        testMessage = true,
        foregroundShow = true,
        notifyId = null,
        image = null,
        inboxContent = null,
        style = null,
        action = null,
        uri = null,
        data = null,
        profileId = null,
        sound = null,
        soundDuration = null,
        ttl = 86400
    }) {
        const url = `${this.baseUrl}/${this.projectId}/messages:send`;
        
        const headers = {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.authorizationToken}`,
            'push-type': '0'
        };

        const notification = {
            category,
            title,
            body,
            clickAction: {
                actionType
            },
            foregroundShow
        };

        if (notifyId !== null) {
            notification.notifyId = notifyId;
        }

        if (image) {
            notification.image = image;
        }

        if (inboxContent && style === 3) {
            notification.style = style;
            notification.inboxContent = inboxContent;
        }

        if (actionType === 1) {
            if (action) notification.clickAction.action = action;
            if (uri) notification.clickAction.uri = uri;
            if (data) notification.clickAction.data = data;
        }

        if (profileId) {
            notification.profileId = profileId;
        }

        if (sound && category !== 'MARKETING') {
            notification.sound = sound;
            if (soundDuration) notification.soundDuration = soundDuration;
        }

        const payload = {
            payload: {
                notification
            },
            target: {
                token: tokens
            },
            pushOptions: {
                testMessage,
                ttl
            }
        };

        try {
            const response = await axios.post(url, payload, { headers, timeout: 30000 });
            return {
                status: 'success',
                code: response.status,
                data: response.data
            };
        } catch (error) {
            return {
                status: 'failed',
                error: error.message,
                code: error.response?.status
            };
        }
    }

    async sendBasicNotification(tokens, title, body) {
        return await this.sendNotification({
            tokens,
            title,
            body,
            category: 'MARKETING',
            actionType: 0,
            testMessage: true
        });
    }

    async sendImageNotification(tokens, title, body, imageUrl) {
        return await this.sendNotification({
            tokens,
            title,
            body,
            category: 'MARKETING',
            actionType: 0,
            testMessage: true,
            image: imageUrl
        });
    }

    async sendMultilineNotification(tokens, title, body, lines) {
        return await this.sendNotification({
            tokens,
            title,
            body,
            category: 'MARKETING',
            actionType: 0,
            testMessage: true,
            inboxContent: lines,
            style: 3
        });
    }

    async sendNotificationWithAccount(tokens, title, body, profileId) {
        return await this.sendNotification({
            tokens,
            title,
            body,
            category: 'MARKETING',
            actionType: 0,
            testMessage: true,
            profileId
        });
    }

    async sendNotificationToInnerPage(tokens, title, body, action = null, uri = null, data = null) {
        return await this.sendNotification({
            tokens,
            title,
            body,
            category: 'MARKETING',
            actionType: 1,
            testMessage: true,
            action,
            uri,
            data
        });
    }

    async sendNotificationWithCustomSound(tokens, title, body, soundFile, duration = 10) {
        return await this.sendNotification({
            tokens,
            title,
            body,
            category: 'TRAVEL',
            actionType: 0,
            testMessage: true,
            sound: soundFile,
            soundDuration: duration
        });
    }
}

const PROJECT_ID = 'your_project_id_here';
const AUTHORIZATION_TOKEN = 'your_jwt_token_here';
const PUSH_TOKENS = ['MAMzLg**********lPW'];

const sender = new PushKitNotificationSender(PROJECT_ID, AUTHORIZATION_TOKEN);

(async () => {
    const result = await sender.sendBasicNotification(
        PUSH_TOKENS,
        '推送服务',
        '推送服务是华为提供的消息推送平台'
    );
    
    console.log('发送结果:', JSON.stringify(result, null, 2));
})();