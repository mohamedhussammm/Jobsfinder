const nodemailer = require('nodemailer');
const config = require('../config');

let transporter;

const getTransporter = () => {
    if (!transporter) {
        transporter = nodemailer.createTransport({
            host: config.email.smtp.host,
            port: config.email.smtp.port,
            secure: config.email.smtp.port === 465,
            auth: {
                user: config.email.smtp.auth.user,
                pass: config.email.smtp.auth.pass,
            },
        });
    }
    return transporter;
};

/**
 * Send an email.
 * @param {Object} options - { to, subject, text, html }
 */
const sendEmail = async ({ to, subject, text, html }) => {
    const mailOptions = {
        from: config.email.from,
        to,
        subject,
        text,
        html,
    };

    if (config.env === 'development') {
        console.log('📧 Email (dev mode):');
        console.log(`   To: ${to}`);
        console.log(`   Subject: ${subject}`);
        console.log(`   Body: ${text || '(HTML email)'}`);
        // In dev, still try to send but don't throw if SMTP is not configured
        try {
            await getTransporter().sendMail(mailOptions);
        } catch (err) {
            console.log('   ⚠️  SMTP not configured, email logged above instead.');
        }
        return;
    }

    await getTransporter().sendMail(mailOptions);
};

module.exports = { sendEmail };
