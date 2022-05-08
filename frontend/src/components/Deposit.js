import React, { useState, useEffect } from 'react';
import Form from 'react-bootstrap/Form';
import Button from 'react-bootstrap/Button';
import './Deposit.css';
import { Card } from 'react-bootstrap';
import WalletCard from './WalletCard';


function Deposit() {
    return (
        <>
            <WalletCard />
            <div className='deposit-wrapper'>
                <Form>
                    <Form.Label>AaveFarm</Form.Label>
                    <Form.Group>
                        <Form.Text className="">
                            Deposit your USDC for 12% yield!
                        </Form.Text>
                    </Form.Group>
                    <Form.Group className="" controlId="">
                        <Form.Control type="email" placeholder="Supply USDC" className="input"/>
                    </Form.Group>
                    <Button variant="primary" type="button" className='btn-style'>
                        Deposit
                    </Button>
                </Form>
                <Button variant="primary" type="button" className='btn-style'>
                    Withdraw
                </Button>
            </div>
        </>
    )
}

export default Deposit;