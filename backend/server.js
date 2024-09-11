const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
const port = 3000;
const secretKey = 'kashin17pass17';

app.use(cors());
app.use(bodyParser.json());

const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'kashin17',
    database: 'attendance_db'
});

db.connect(err => {
    if(err) throw err;
    console.log('connection successful');
});

function deg2rad(deg){
    return deg * (Math.PI/100);
}

function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2){
    const R = 6371;
    const dLat = deg2rad(lat2 - lat1);
    const dLon = deg2rad(lon2 - lon1);
    const a = 
        Math.sin(dLat/2) * Math.sin(dLat/2) +
        Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R*c;
}

function authenticateToken(req, res, next){
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    console.log('Received Token:', token);

    if(token == null) return res.sendStatus(401);
        

    jwt.verify(token, secretKey, (err,user) => {
        if(err){
            console.log('Token Verification Error:', err);
            return res.sendStatus(403);
        }     
        req.user = user;
        next();
    });
}

app.post('/register', async(req,res) => {
    const{username, password} = req.body;
    const hashedPassword = await bcrypt.hash(password,8);

    const sql = 'INSERT INTO users (username , password) VALUES (?,?)';
    db.query(sql, [username, hashedPassword], (err, result) => {
        if(err) throw err;
        res.send('User registered');
    });
});

app.post('/login', (req,res) => {
    const {username,password} = req.body;

    const sql = 'SELECT * from users where username = ?';

    db.query(sql,[username], async (err,results) => {
        if(err) throw err;

        if(results.length === 0){
            return res.status(401).send('User Not found');
        }

        const user = results[0];
        const validPassword = await bcrypt.compare(password, user.password);

        if(!validPassword){
            return res.status(401).send('Invalid Password');
        }

        const token = jwt.sign({userId: user.id}, secretKey,{ expiresIn: '1h'} );
        console.log(user.id);
        res.json({token});
    });
    
});

app.post('/checkin', authenticateToken, (req,res) =>{
    const {latitude , longitude} = req.body;
    const userId = req.user.userId;
    //const officeLat = 12.9715987;
    //const officeLat = 28.560589;  //nhpc
    const officeLat = 37.422094;  //nhpc

    //const officeLon = 77.5945627;
    const officeLon = -122.083922; //nhpc

    const radius = 0.1; // 0.1 = 100 meters

    const distance = getDistanceFromLatLonInKm(latitude,longitude,officeLat,officeLon);

    const radius_check = distance <= radius;

    console.log(userId);

    const sql = 'INSERT INTO attendance (user_id, check_in_time, latitude,longitude, radius_check) VALUES (?,NOW(),?,?,?)';
    db.query(sql,[userId,latitude,longitude,radius_check], (err,result) => {
        if(err) throw err;
        res.send('Check-in successful');
    });
    
});

app.get('/records/:userID', authenticateToken, (req,res) => {
    //const userID = req.params.userID;
    const userID = req.user.userId;
    const query = 'SELECT * FROM attendance WHERE user_id = ?';

    db.query(query,[userID], (err,results) => {
        if(err) throw err;
        res.json(results);
    });
});

app.get('/todayrecords/:userID', authenticateToken, (req,res) => {
    //const userID = req.params.userID;
    const userID = req.user.userId;
   // const query = 'SELECT * FROM attendance WHERE user_id = ?';
    const query = 'SELECT * FROM attendance WHERE DATE(check_in_time) = CURDATE() AND user_id = ?';

    db.query(query,[userID], (err,results) => {
        if(err) throw err;
        res.json(results);
    });
});

app.get('/monthlyrecords/:userID/:year/:month', authenticateToken, (req,res) => {
    const userID = req.params.userID;
    const year= req.params.year;
    const month = req.params.month;

    const query = 'SELECT DATE(check_in_time) AS date, TIME(check_in_time) AS time, radius_check FROM attendance WHERE user_id=? AND YEAR(check_in_time)=? AND MONTH(check_in_time)=? ORDER BY date,time';

    db.query(query,[userID, year, month], (err,results) => {
        if(err) throw err;
        res.json(results);
    });
});




app.listen(port,() => {
    console.log('server running on port ${port}');
});