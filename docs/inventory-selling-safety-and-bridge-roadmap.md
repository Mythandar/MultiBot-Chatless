# Inventory selling safety and bridge roadmap

## Purpose

This document records the investigation and implementation completed in August 2026 for MultiBot's bot-inventory selling controls. It also defines the recommended replacement for chat-based selling through `mod-multibot-bridge`.

## Reported behavior

Individual items normally sold through an addon-generated whisper:

```text
s <item hyperlink>
```

Some rare items, including Buzzer Blade, Smite's Reaver, and Rift Bracers, did not produce an outgoing whisper when clicked. Manually whispering the plain item name, for example `s Rift Bracers`, sold the item successfully. This isolated the failure to the addon's hyperlink-based chat path rather than playerbot selling rules, vendor eligibility, GM permissions, or item quality policy.

The server-side playerbot `SellAction` accepts explicit items without a rare-quality restriction. Bulk `s *` is intentionally limited to poor-quality items, while `s vendor` uses playerbot item-usage classification.

## Implemented addon behavior

### Hyperlink-first sell with a name fallback

Individual Sell keeps the original behavior when it works:

1. Send `s <displayed item hyperlink>`.
2. Observe `CHAT_MSG_WHISPER_INFORM` for confirmation that the client emitted that exact whisper to the selected bot.
3. If no outgoing confirmation arrives within one second, send `s <plain item name>`.

The delay is for outgoing-whisper confirmation, not the bot's `Selling ...` response. It prevents both commands from being sent for links that work normally. Plain-name matching is a compatibility fallback and has known ambiguity described below.

### Maximum sell rarity

Options -> MultiBot -> Inventory contains a saved **Maximum sell rarity** setting. It defaults to Rare, allowing blue items and below while blocking Epic and Legendary items. The value is stored per controlling character in:

```text
MultiBotDB.profile.ui.inventory.maxSellQuality
```

Quest items, keys, and the Hearthstone remain independently protected. Missing or uncached quality information is treated conservatively and blocked.

### Sell Vendor safeguard

`s vendor` runs playerbot's item-usage classification on the server and cannot honor the addon's per-item rarity check. The Sell Vendor button therefore requires Shift-click, and its tooltip explicitly states that it bypasses the maximum-rarity setting. Sell Grey remains predictable because `s *` only selects poor-quality items.

### Inventory refresh behavior

Clicking Sell immediately hides the selected icon. The addon registers the complete displayed stack as a pending removal so stale bridge inventory snapshots cannot recreate it while the hyperlink/fallback decision is settling. Refreshes are initiated only after the effective command path settles, followed by a second refresh for final server confirmation. Once the updated snapshot arrives, the remaining item grid compacts and removes the temporary empty slot.

## Verified results

Manual client testing confirmed:

- ordinary items can still sell with hyperlinks;
- Buzzer Blade falls back after one second to `s Buzzer Blade` and sells;
- previously failing rare items sell through the name fallback;
- the rarity limit blocks items above the configured quality without sending a sell command;
- the selected rarity persists through normal logout and login;
- Sell Vendor requires Shift-click;
- stale inventory responses no longer permanently restore a sold item's icon.

## Current limitations

The chat fallback is deliberately compatible with the existing playerbot interface, but it is not perfectly unambiguous:

- playerbot name matching is case-insensitive substring matching;
- multiple stacks or items matching the same name may all be selected;
- generated random-suffix names may differ from the server template name;
- client and server localization can disagree;
- chat hyperlink acceptance remains controlled by the 3.3.5 client and AzerothCore link validation;
- no chat command identifies one physical item instance.

The current bridge inventory snapshot also aggregates all bag items by item ID. It does not expose a unique item GUID or bag/slot location, so the addon cannot yet target one exact stack through the bridge.

## Recommended bridge implementation

### Phase 1: item-ID selling

Extend the existing tokenized inventory action protocol:

```text
RUN ITEM_ACTION~<bot>~<token>~SELL_ITEM~<itemId>~<count>~<maxQuality>
```

Add `SELL_ITEM` handling beside `BANK_DEPOSIT`, `BANK_WITHDRAW`, `GBANK_DEPOSIT`, `GBANK_WITHDRAW`, and `BUY_ITEM` in `RunInventoryItemActionCommand`.

The bridge handler should:

1. Resolve and authorize the controlled bot with `FindBotByName`.
2. Find an interactable nearby creature with `UNIT_NPC_FLAG_VENDOR`.
3. Locate matching items only in the bot's carried bags.
4. Reject quest items, keys, the Hearthstone, non-sellable templates, and items above the lower of the requested safety limit and a server-configured ceiling.
5. Sell through the normal AzerothCore vendor/session path so buyback, money, hooks, logging, and item removal behave like an ordinary sale.
6. Return a token-correlated `INVENTORY_ITEM_ACTION` result containing `OK` or `ERR`, a stable reason code, and the quantity moved.
7. Refresh inventory only after the acknowledgement.

Useful reason codes include:

```text
NO_BOT
NO_AI
VENDOR_NOT_FOUND
ITEM_NOT_FOUND
ITEM_PROTECTED
QUALITY_BLOCKED
ITEM_NOT_SELLABLE
SELL_FAILED
OK
```

For compatibility with current explicit playerbot selling, `count = 0` can mean all matching carried stacks. A positive count should cap the number sold.

### Phase 2: exact item-instance selling

The preferred final design is to stop aggregating the bridge inventory solely by item ID. Emit one inventory record per stack with at least:

```text
itemId
itemGuid or bag/slot
stackCount
quality
soulbound
canonical display link
```

Then extend `ITEM_ACTION` with the item GUID or bag/slot identity. The server must revalidate that the identified item still belongs to the selected bot and remains in the reported bag slot before selling it. Never trust quality, protection, ownership, price, or vendor eligibility supplied by the client.

This design provides:

- exact-stack selection;
- no hyperlink validation dependency;
- no localized-name matching;
- no substring ambiguity;
- authoritative success/failure acknowledgement;
- deterministic inventory refresh timing;
- a foundation for exact Equip, Trade, Use, Destroy, Bank, and Guild Bank actions.

### Addon migration

When `SELL_ITEM` is advertised by the bridge protocol, individual Sell should call `MultiBot.Comm.RunInventoryItemAction` first. The existing hyperlink/name flow should remain only as a compatibility fallback for older servers. On bridge acknowledgement, clear pending UI state and request a fresh inventory snapshot. On error, restore the item and display the mapped reason without attempting a second destructive command automatically.

The saved rarity setting should remain in the addon for user experience and be included in the request. The bridge should independently validate it and apply a server-configured maximum, so a modified client cannot bypass the server's destructive-action policy.

## Buy command note

The bridge already supports `BUY_ITEM` by item ID. Playerbots does not require an existing copy of an item to buy it. The inventory-window Buy button currently appears on an existing inventory item because that UI obtains its item ID from the clicked button. The profession recipe window can request missing material IDs even when the bot has none, provided a nearby vendor sells them.
