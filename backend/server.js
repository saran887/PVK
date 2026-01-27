require('dotenv').config();
const express = require('express');
const axios = require('axios');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// MSG91 Authkey (Loaded from .env file)
const AUTHKEY = process.env.MSG91_AUTHKEY;

// Middleware
app.use(cors()); // Enable CORS for Flutter web/mobile requests
app.use(express.json()); // Parse JSON request bodies

/**
 * POST /verify-msg91-token
 * Receives the accessToken from the Flutter app and verifies it with MSG91
 */
app.post('/verify-msg91-token', async (req, res) => {
    try {
        const { accessToken } = req.body;

        // Basic validation
        if (!accessToken) {
            return res.status(400).json({
                status: 'error',
                message: 'Access token is required'
            });
        }

        // Call MSG91 API to verify the access token
        const response = await axios.post(
            'https://control.msg91.com/api/v5/widget/verifyAccessToken',
            {
                "authkey": AUTHKEY,
                "access-token": accessToken
            },
            {
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                }
            }
        );

        // Return the response from MSG91 directly to the client
        return res.status(response.status).json(response.data);

    } catch (error) {
        console.error('Error verifying MSG91 token:', error.response?.data || error.message);

        // Handle API failures or network errors
        const statusCode = error.response?.status || 500;
        const errorMessage = error.response?.data || { message: 'Internal Server Error' };

        return res.status(statusCode).json(errorMessage);
    }
});

// Start the server
app.listen(PORT, () => {
    console.log(`MSG91 Verification Server running on http://localhost:${PORT}`);
    console.log(`Endpoint: POST http://localhost:${PORT}/verify-msg91-token`);
});
