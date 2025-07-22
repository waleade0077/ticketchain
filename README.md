# TicketChain Smart Contract

TicketChain is an on-chain ticketing platform for events, enabling secure ticket minting, resale, royalty management, and validation using the Clarity smart contract language on the Stacks blockchain.

## Features

- **Event Creation:** Organizers can create events with customizable royalty and resale cap settings.
- **Ticket Minting:** Event organizers mint tickets for their events, setting initial prices.
- **Primary Sale:** Users can purchase tickets directly from organizers.
- **Resale & Royalties:** Ticket owners can resell tickets within event-defined price caps. Royalties are automatically paid to organizers on secondary sales.
- **Ticket Validation:** Organizers can validate tickets for entry, marking them as used.
- **Burn & Transfer:** Ticket owners can burn (delete) unused tickets or transfer them to other users.
- **Read-Only Queries:** Retrieve event and ticket details.

## Contract Functions

### Event Management
- `create-event(name, date, royalty, resale-cap)`  
  Create a new event. Only the sender becomes the organizer.

### Ticket Operations
- `mint-ticket(event-id, price)`  
  Organizer mints a ticket for their event.
- `buy-ticket(ticket-id)`  
  Purchase a ticket from the organizer.
- `resell-ticket(ticket-id, new-price)`  
  Owner lists a ticket for resale, respecting the event's resale cap.
- `buy-resale-ticket(ticket-id)`  
  Purchase a resale ticket, automatically paying royalties to the organizer.
- `validate-ticket(ticket-id)`  
  Organizer validates a ticket for entry, marking it as used.
- `burn-ticket(ticket-id)`  
  Owner deletes an unused ticket.
- `transfer-ticket(ticket-id, to)`  
  Owner transfers a ticket to another principal.

### Read-Only Queries
- `get-ticket(ticket-id)`  
  Returns ticket details.
- `get-event(event-id)`  
  Returns event details.

## Error Codes

- `u100`: Not organizer
- `u101`: Ticket is for resale, use resale function
- `u102`: Unauthorized or price cap exceeded
- `u103`: Ticket not for resale
- `u104`: Validation failed (already used or not organizer)
- `u105`: Burn failed (not owner or already used)
- `u106`: Transfer failed (not owner)
- `u107`: Not found (ticket or event)
- `u108`: STX transfer to seller failed
- `u109`: STX transfer to organizer failed

## Usage

Deploy the contract to the Stacks blockchain. Interact using Clarity calls via your preferred wallet, CLI, or dApp interface.

## Development

- Contract source: [`contracts/ticketchain.clar`](contracts/ticketchain.clar)
- Ignore files: See [.gitignore](.gitignore) for development artifacts.
